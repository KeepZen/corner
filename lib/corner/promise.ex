defmodule Corner.Promise do
  @moduledoc """
  The Promise in Elixir.
  
  Smarily as Promise in Javascript.
  """
  @doc false
  use GenServer

  @opaque t :: %__MODULE__{
            pid: pid(),
            state: :pending | :stop
          }
  defstruct pid: nil, state: :pending

  @type resolver :: (any -> any)
  @type rejecter :: (any -> any)
  # If promise is done but after `@receive_time`, not call `await` to get the result,
  # process will stoped.
  @receive_time 60 * 1000
  @doc """
  Dynamic create a new promise with `fun`.
  
  The spectype of `fun` is `(resolver,rejecter)-> any`.
  + When `resolver` is call, promise will turn to `:resolved`.
  + When `rejecter` is call, promise will turn to `:rejected`.
  + When both be called in `fun`, statue of promise will turn
  to the one who is first be called.
  """
  @spec new(fun :: (resolver(), rejecter() -> any)) :: t()
  def new(fun, receive_time \\ @receive_time) when is_function(fun, 2) do
    {:ok, pid} = GenServer.start(__MODULE__, [fun, self(), receive_time])
    %__MODULE__{pid: pid}
  end

  @doc """
  Create promise with data.
  The `tag` can be `:resolved` or `:rejected`, default is `:resolved`.
  """
  @spec of(any, :resolved | :rejected) :: t
  def of(v, tag \\ :resolved) do
    if is_struct(v, __MODULE__) do
      v
    else
      new(fn resolver, rejecter ->
        case tag do
          :resolved -> resolver.(v)
          :rejected -> rejecter.(v)
        end
      end)
    end
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

  @typedoc """
  The function passed to `Promise.then/1-2`.
  """
  @type resolve_then :: (any -> any)
  @type rejecte_then :: (any -> any)
  @type error_then :: ({:error | :stop, any} -> any)
  @type error_handler :: rejecte_then() | error_then()

  @doc """
  Transform the data or hanlde the error.
  
  + `then/2`: Transform the data with `fun1`, but if  promise on error,
  hanlder error whith `fun2`.
  + `then/1`: Transform the data with `fun1`, if promise on error,
  just skip the `fun1`.
  """
  @spec then(t, nil | resolve_then(), nil | error_handler) :: t()
  def then(promise, fun1, fun2 \\ nil)

  def then(%__MODULE__{} = this, fun1, fun2)
      when is_function(fun1, 1) and
             (fun2 == nil or is_function(fun2, 1)) do
    async_send_run(this, fun1, fun2)
  end

  @doc """
  Trasform the state of promise with `fun`.
  
  + If promise's state on `:resolved` or `:rejected`, `fun` get the value of
  promise.
  + On `:error`, `fun` get `{:error, {any, []}}`
  """
  @spec map(t, resolve_then() | error_handler()) :: t
  def map(%__MODULE__{} = promise, fun) when is_function(fun, 1) do
    async_send_run(promise, fun, fun)
  end

  @doc """
  Add a error handelr for the promise.
  """
  @spec on_error(t, error_handler) :: t
  def on_error(%__MODULE__{} = promise, fun) when is_function(fun, 1) do
    async_send_run(promise, nil, fun)
  end

  @type tag :: :resolved | :rejected | :error | :stop
  @doc """
  Get value from `promise`.
  
  Return `{tag, value}`, where tag is `:resolved | :rejected | :error | :stop`.
  """
  @spec await(t) :: {tag, any}
  def await(%{pid: pid}) do
    if Process.alive?(pid) do
      send(pid, {:await, self()})

      receive do
        {:result, message} -> message
      after
        :infinity -> {:stop, :bad}
      end
    else
      {:stop, :done}
    end
  end

  # Server
  @impl true
  def init([fun, pid, receive_time]) do
    state = %{
      receive_time: receive_time,
      sender_ref: make_ref(),
      state: :pending,
      sender: pid,
      timer_ref: nil,
      result: nil
    }

    {:ok, state, {:continue, fun}}
  end

  @impl true
  def handle_continue(fun, %{state: :pending} = state) do
    %{sender_ref: sender_ref} = state

    run_and_handle_error(
      fn _ ->
        fun.(&resolver(sender_ref, &1), &rejecter(sender_ref, &1))
        throw({sender_ref, :stop})
      end,
      state
    )
  end

  @impl true
  def handle_cast({:run, fun, _}, %{state: :resolved} = state)
      when is_function(fun, 1) do
    run_and_handle_error(fun, state)
  end

  # reject happend but no error_hanlder
  def handle_cast({:run, _fun, nil}, %{state: tag} = state)
      # _fun is not nil
      when tag != :resolved do
    noreply(state)
  end

  # resolved happend but just error_hanler
  def handle_cast({:run, nil, _fun}, %{state: :resolved} = state) do
    noreply(state)
  end

  def handle_cast({:run, _fun, fun}, %{state: tag} = state)
      when tag != :resolved do
    run_and_handle_error(fun, state)
  end

  @impl true
  def handle_info({:timeout, ref}, %{sender_ref: ref} = state) do
    {:stop, :normal, %{state | sender_ref: nil}}
  end

  def handle_info({:timeout, _}, state) do
    noreply(state)
  end

  def handle_info({:await, waiter}, %{state: tag, result: v} = state) do
    send(waiter, {:result, {tag, v}})
    {:stop, :normal, state}
  end

  # private
  defp run_and_handle_error(fun, %{state: tag, result: result} = state) do
    if state.timer_ref, do: :timer.cancel(state.timer_ref)

    try do
      if tag == :error, do: fun.({tag, result}), else: fun.(result)
    catch
      kind, error -> catch_error(kind, error, __STACKTRACE__, state)
    else
      v ->
        message = {:timeout, state.sender_ref}
        timer_ref = Process.send_after(self(), message, state.receive_time)

        %{state | timer_ref: timer_ref, state: :resolved, result: v}
        |> noreply()
    end
  end

  defp catch_error(:throw, {ref, :stop}, _, %{sender_ref: ref} = state) do
    send(state.sender, {:result, {:stop, :done}})
    Process.exit(self(), :kill)
  end

  defp catch_error(:throw, {ref, tag, result}, _, %{sender_ref: ref} = state) do
    message = {:timeout, ref}
    timer_ref = Process.send_after(self(), message, state.receive_time)

    %{state | timer_ref: timer_ref, state: tag, result: result}
    |> noreply()
  end

  defp catch_error(tab, error, stacktrace, %{sender_ref: ref} = state)
       when tab in [:error, :throw] do
    message = {:timeout, ref}
    timer_ref = Process.send_after(self(), message, state.receive_time)
    result = {error, stacktrace}

    %{state | timer_ref: timer_ref, state: :error, result: result}
    |> noreply()
  end

  defp noreply(state), do: {:noreply, state}
  @normal_tags [:resolved, :rejected]
  @sender_names [:resolver, :rejecter]

  for {name, tag} <- Enum.zip(@sender_names, @normal_tags) do
    defp unquote(name)(ref, v) do
      throw({ref, unquote(tag), v})
    end
  end

  defp async_send_run(%__MODULE__{pid: pid} = m, fun1, fun2) do
    if is_pid(pid) and Process.alive?(pid) do
      GenServer.cast(pid, {:run, fun1, fun2})
      m
    else
      %{m | state: :stop}
    end
  end
end
