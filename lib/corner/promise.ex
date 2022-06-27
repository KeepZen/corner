defmodule Corner.Promise do
  use GenServer

  @opaque t :: %__MODULE__{
            pid: pid()
          }
  defstruct pid: nil, state: :pending

  @type resolver :: (any -> any)
  @type rejecter :: (any -> any)
  @doc """
  Dynamic create a new promise with `fun`.
  The spectype of `fun` is `(resolver,rejecter)-> any`.
  + When `resolver` is call, promise will turn to `:resolved`.
  + When `rejecter` is call, promise will turn to `:rejected`.
  + When both be called in `fun`, statue of promise will turn
  to the one who is first be called.
  """
  @spec new(fun :: (resolver(), rejecter() -> any)) :: t()
  def new(fun) when is_function(fun, 2) do
    {:ok, pid} = GenServer.start(__MODULE__, [fun, self()])
    %__MODULE__{pid: pid}
  end

  @doc """
  Create promise with data.
  The `tag` can be `:resolved` or `:rejected`, default is `:resolved`.
  """
  @spec of(any, :resolved | :rejected) :: t
  def of(v, tag \\ :resolved) do
    new(fn resolver, rejecter ->
      if tag == :resolved do
        resolver.(v)
      else
        rejecter.(v)
      end
    end)
  end

  @doc """
  Create a `:resolved` promise.
  """
  def resolve(v) do
    of(v)
  end

  @doc """
  Create a `:rejected` promise.
  """
  def reject(v) do
    of(v, :rejected)
  end

  @type resolve_then :: (any -> any)
  @type rejecte_then :: (any -> any)
  @type error_then :: ({:error | :timeout | :stop, any} -> any)
  @type error_handler :: rejecte_then() | error_then()
  @spec then(t, nil | resolve_then(), nil | error_handler) :: t()
  def then(promise, fun1, fun2 \\ nil)

  def then(%__MODULE__{} = this, fun1, fun2)
      when is_function(fun1, 1) and
             (fun2 == nil or is_function(fun2, 1)) do
    sync_send_run(this, fun1, fun2)
  end

  @spec map(t, resolve_then() | error_handler()) :: t
  def map(%__MODULE__{} = this, fun) when is_function(fun, 1) do
    sync_send_run(this, fun, fun)
  end

  @spec on_error(t, error_handler) :: t
  def on_error(%__MODULE__{} = this, fun) when is_function(fun, 1) do
    sync_send_run(this, nil, fun)
  end

  @type tag :: :resolved | :rejected | :error | :timeout | :stop
  @spec await(t, non_neg_integer() | :infinity) :: {tag, any}
  def await(%{} = this, timeout \\ :infinity) do
    if Process.alive?(this.pid) do
      send(this.pid, {:await, self()})

      receive do
        {:result, message} -> message
      after
        timeout -> {:timeout, this.pid}
      end
    else
      {:stop, :ok}
    end
  end

  # Server
  @impl true
  def init([fun, pid]) do
    {:ok,
     %{
       state: :pending,
       result: nil,
       waiter: nil
     }, {:continue, [fun, pid]}}
  end

  @impl true
  def handle_continue([fun, pid], %{state: :pending} = state) do
    Process.monitor(pid)
    run_and_send_message_back(fn -> fun.(&resolver/1, &rejecter/1) end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:change_state, v}, %{state: tag} = state)
      when tag != :waiting_result do
    {tag, result} = v
    {:noreply, %{state | state: tag, result: result}}
  end

  def handle_cast({:change_state, v}, %{state: :waiting_result} = state) do
    {tag, result} = v
    send(state.waiter, {:result, {tag, result}})
    {:stop, :normal, %{state | state: :stop}}
  end

  @impl true
  def handle_call({:run, fun, _}, _from, %{state: :resolved} = state)
      when is_function(fun, 1) do
    run_and_handle_error(fn -> fun.(state.result) end, state)
  end

  def handle_call({:run, _fun, fun}, _from, %{state: :rejected} = state)
      when is_function(fun, 1) do
    run_and_handle_error(fn -> fun.(state.result) end, state)
  end

  @error_tags [:error, :rejected, :stop]
  def handle_call({:run, _fun, fun}, _from, %{state: tag} = state)
      when tag in @error_tags and is_function(fun, 1) do
    run_and_handle_error(fn -> fun.({tag, state.result}) end, state)
  end

  def handle_call({:run, _fun, nil}, _from, %{state: tag} = state)
      when tag in @error_tags do
    {:reply, :ok, state}
  end

  def handle_call({:run, nil, _fun}, _from, %{state: tag} = state)
      when tag in [:pending, :resolved] do
    {:reply, :ok, state}
  end

  @wait_state [:pending, :stop]
  @impl true
  def handle_info({:await, waiter}, %{state: tag} = state)
      when tag not in @wait_state do
    message = {tag, state.result}
    send(waiter, {:result, message})
    {:stop, :normal, %{state | state: :stop}}
  end

  def handle_info({:await, waiter}, %{state: tag} = state)
      when tag in @wait_state do
    {:noreply, %{state | state: :waiting_result, waiter: waiter}}
  end

  def handle_info(
        {:DOWN, _ref, :process, _object, _reason},
        %{waiter: nil} = state
      ) do
    send(self(), :stop)
    {:noreply, state}
  end

  def handle_info(:stop, state) do
    {:stop, :normal, %{state | state: :stop}}
  end

  # private

  senders = [
    resolver: :resolved,
    rejecter: :rejected,
    error_handler: :error
  ]

  for {name, tag} <- senders do
    defp unquote(name)(v) do
      message = {unquote(tag), v}
      GenServer.cast(self(), {:change_state, message})
    end
  end

  defp run_and_send_message_back(fun) do
    fun.()
  catch
    :error, err ->
      error_handler({err, __STACKTRACE__})
  end

  defp run_and_handle_error(fun, state) do
    v = fun.()
    {:reply, :ok, %{state | state: :resolved, result: v}}
  catch
    :error, err ->
      {:reply, :ok, %{state | state: :error, result: {err, __STACKTRACE__}}}
  end

  defp sync_send_run(%__MODULE__{pid: pid} = p, fun1, fun2) do
    GenServer.call(pid, {:run, fun1, fun2})
    p
  end
end
