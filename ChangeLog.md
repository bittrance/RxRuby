# RxRuby Change log

## Release 0.1.0

### Removed operators and classes
Note that these removals are mostly motivated by reducing the amount of code to write tests for; we may well want to introduce them again later.

- Remove `Observable.subscribe_on_next/error/completed` as they are problematic in that it is not clear that you can only use one of them.
- Remove `ObserveOnObserver` and make its superclass `ScheduledObsever` take its role; they did not have a clean separation of concerns.
- Remove `Observer.create`; having a specific method for triple-lambda is not worth the confusion; use `Observer.configure` instead.
- Remove stub `ReplaySubject` until it can be properly implemented.
- Remove `.contains` which duplicates `.contains?`
- Remove `.dispose` on subscriptions. While the name dispose/disposable might be more distinct, the codebase is dominated by subscribe/unsubscribe/subscription.
- Remove `.element_at_or_default`, `.first_or_default`, `.last_or_default`, `.single_or_default` operators and equip `.element_at`, `.first`, `.last`, `.single` with optional default value parameters.
- Remove `.min_by` and `.max_by`. These are inspired by Ruby where they add convenience over `.min/.max` by allowing you to pick the to compare, but unlike Ruby's return lists. They seem to have no equivalent in other modern ReactiveX implementations.
- Remove `.pairs` which is not correctly implemented; try `.buffer_with_count(2)`.
- Remove `.take_last_buffer`. Use `.take_last(n).to_a` instead; this method is no longer in RxJS 5 either.
- Remove `.tap` as an alias of `.do`; `.tap` is a Ruby object builtin and quite useful on Observables in some cases.
- Remove `.when`, `.and` operators because of the extensive testing/fixing needed; try `.fork_join` or `.zip` instead.

### Breaking changes

- `.delay_with_selector` now accepts a block as selector rather than a lambda.
- `.distinct_until_changed` now accepts a comparator function, using `<=>` for default.
- `.if` no longer takes a scheduler to pass to empty else arguments; if you really need to pass the completion on a separate scheduler you will have to pass your own `.empty`.
- `.min` and `.max` now takes a block that will get two arguments comparator-style and is expected to return -1, 0 or 1 much as `<=>` (which is the default comparator).
- `.timestamp` now emits structs rather than hash values to reduce risk of confusion with processed values.
- Drop support for Ruby 1.8.

### Bugfixes

- `BehaviorSubject` now handles `on_error`, `on_completed`.
- `ConnectableObservable.ref_count` counts references properly and unsubscribes on last.
- `.any?` now applies block with `.select` rather than `.map` as `.map` will always emit, making `.any?` return true regardless of input.
- `.average`, `.sum` generates detailed exceptions on non-numerical input.
- `.concat` now unsubscribes sources when they are exhausted.
- `DefaultScheduler` scheduling actions previously did `Thread#exit` on unsubscribe. However, where the scheduling call (e.g. `subscribe_on`) occurs in the middle of a chain, we do not actually know that the thread is done when the scheduling subscription `unsubscribe` method is triggered (e.g. by `AutoDetachObserver`). This resulted in operations like `.merge_all` and `.merge_concurrent` that lack rigid connection between upstream and downstream subscriptions would work fine in synchronous operation, but the stream would mysteriously die when put on `DefaultScheduler`. Given that `Thread.exit` on a worker thread with a finite lifecycle is a dubious concept at the best of times, this PR simply removes the composite subscription and passes out a `SingleAssignmentSubscription` instead.
- `.delay` now propagates errors immediately.
- `.distinct_until_changed` now treats `nil` as an ordinary value.
- `.first`, `.element_at` now on_errors rather than raise on "sequence contains no elements".
- `.fork_join` avoids lambda return which fails on older Ruby.
- `.group_join` now emits right-hand values on left-hand subjects.
- `.group_join` right duration exceptions now inform subjects.
- `.latest` now unsubscribes inner observables.
- `.latest` now completes only when both outer and inner observable has completed.
- `.materialize` now emits errors as `on_error` notifications (rather than `on_next` notifications)
- `.merge` now propagates unsubscribes to inner observables.
- `.merge_concurrent` now propagates unsubscribes to inner observables.
- `.multicast` subscribes properly to its connectable.
- `.none?` now `.select` according to block (rather than block negation; since `.any?` is fail-fast) and then map-invert the result (like `.all?`).
- Recursively scheduled items now produce proper subscriptions so that they can be cancelled.
- `.rescue_error` actually tries left observable (i.e. self) before trying alternate observable.
- `.sample` now respects `nil` values.
- `.sample` propagates recipe exceptions properly.
- `.scan` operator use next instead of break.
- `ScheduledObserver` passes error to wrapped observer or it is very likely to "disappear" since we are very likely to be on a thread.
- `.sequence_eql?` now unsubscribes completed sequences immediately, rather than when the slowest sequence completes.
- `.skip_until` now completes if upstream completed without emission.
- `.skip_while`, `.skip_while_with_index` now continue emitting values after they stop skipping.
- `.take_last` now emits the correct number of items, rather than always emitting zero values.
- `.to_h` now uses value selector properly.
- `.window_with_time` now unsubscribes properly.
- `.zip` needs to catch errors in result selector.
- New, thread-aware Enumerator implementation used by `.concat`, `.repeat_infinitely` and others. RxRuby was using Ruby Enumerator for as an internal short-hand for repeating an Observable a fixed or infinite number of times, for example the `.repeat_infinitely` operator. The problem with this is that MRI's Enumerator is explicitly thread-averse, as is described in #4 and #10. This affects all places where one part of RxRuby is passing an Enumerator to another part, since the caller cannot know if the receiving observable will be executed across more than one thread.

### Improvements:

- Remove instance version of `.combine_latest` in favour of delegating to class-level `.combine_latest`.
- Remove internally unused time-math methods from test scheduler.
- `.debounce` raises argument error on negative numbers.
- Implement time-based `.timer`.
- `CurrentThreadScheduler` uses a thread-local queue rather than a class member queue.
- `CurrentThreadScheduler` is a singleton and can refer to instance members rather than class methods.
- Properly synchronise `.delay` operator.
- Reimplement `.merge_all` as `.merge_concurrent` with infinite concurrency since the latter is properly synchronised.
- Shared scheduler tests no longer delays test execution ~6 seconds; MRI now executes tests in about 2 seconds.
- `.multicast` defaults to transparent selector so you don't have to give two arguments.
- `.publish` block is now properly optional.
- `.multicast` does not accept selector when passed a single subject.
- `ConnectableObservable.ref_count` now raises when it has already been `.connect`:ed.
- `.skip`, `.take` now throws `ArgumentError` on negative count.
- reimplement `.window_with_time` for better readability and properly managed subscriptions. Also fixes the issue that the first window goes first when scheduled on test scheduler, while subsequent windows go after value emission in a particular time slot; an issue since the marble tests don't increment time by 1 for "simultaneous" events.
- subscribing to disposed `Subject`s yields `RuntimeError`.
- `AsycSubject`, `BehaviorSubject`, `Subject` delegate subscribing to `Observable.subscribe`.
- clarify that instance `.rescue_error` won't accept both alternate observable and block.
- `.merge_concurrent` validates that max_concurrency is integer.
- `.merge_concurrent` class version can now be called without scheduler argument as intended.
- `.zip` should complete as soon as there is no chance of another pair, i.e. when one source has been exhausted and has completed.
- `.for` block is a "transform", rather than a "result selector".
- ensure argument to `.repeat` is an integer.
- `Rx::Subject` allows the normal subscription styles that `Observable.subscribe` uses - it is an Observable, after all. This PR simply uses the `subscribe` method from `Rx::Observable` to normalise the observer setup and instead overrides `_subscribe`. This also fixes a bug where `.to_a` assumed that you could use the three-lambda subscription form on itself: https://github.com/bittrance/rxruby/blob/caea16f7e723e8ea6f2241210abae5009b1827c6/lib/rx/operators/aggregates.rb#L523.
- `.do` no longer requires all three lambdas to be supplied. Despite defaulting its first argument to `nil`, `.do` unhelpfully threw nil-class errors on e.g. `.do(nil, lambda {|e| ... }, lambda { ... })`.
