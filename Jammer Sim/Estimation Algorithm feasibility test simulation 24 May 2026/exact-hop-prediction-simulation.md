# Exact-Hop Prediction Pretraining Simulator

## Purpose

`exact-hop-prediction.html` answers the "infinite resources" version of the project question:

If the jammer can pretrain with active feedback before deployment, what is the best possible method for predicting exact future hops?

The best theoretical method is not a normal follower, active-map learner, or neural network trained only to approximate the next channel. It is full system identification:

1. Treat the hop selector as a hidden finite-state generator.
2. Maintain a posterior over every possible hidden state, clock phase, key, map, and model parameter.
3. Use active feedback during pretraining to collapse that posterior.
4. At deployment, roll the recovered state forward to the required response-time horizon.
5. Jam the predicted one-MHz bin, or center a wider jam window on that bin.

With infinite compute and enough clean feedback, this is the optimal Bayesian predictor for any hop process contained in the model class.

## Why This Is Different From Active-Map Learning

The earlier active-map simulator learns where traffic tends to occur. It does not know the exact next hop, so even its oracle bound is limited by the amount of probability mass inside a contiguous window.

Exact-hop prediction is stronger. If the hidden sequence state is known, the predictor can target one exact future bin. In the ideal case, a 1 MHz jammer can disrupt nearly 100% of packets in the simplified model.

This is the ceiling case, not the default engineering case.

## Simulated Target Models

`Finite-state affine kernel`

A deterministic 79-channel sequence with hidden phase and stride. This is the easiest case and demonstrates posterior collapse.

`Permuted finite-state kernel`

Adds a hidden channel permutation. The sequence is still deterministic but less directly stride-like.

`Affine kernel with AFH remap`

Generates an unmapped hop and remaps it into an active-channel set. This models a deterministic sequence interacting with a reduced active map.

`Unmodelled stochastic drift`

Adds randomness after pretraining. This shows the hard limit: infinite compute cannot exactly predict randomness that is not contained in the learned model.

## Predictors Included

`Bayesian Exact-State Predictor`

The main theoretical method. It enumerates candidate hidden generators during pretraining, scores them against feedback, and deploys the highest-posterior generator.

`Posterior Majority Vote`

Keeps a weighted ensemble of remaining candidates and predicts the channel with the most posterior mass. This is useful when the posterior has not collapsed to one state.

`Transition Memorizer`

A fallback that learns observed transitions but does not recover the hidden generator.

`Active-Map Mode`

A density fallback that predicts the most common observed channel.

`Random One-Bin`

The one-channel random baseline. In a 79-channel model it should sit near:

```text
1 / 79 = 1.27%
```

## Interpreting Results

If the posterior collapses to one live candidate and exact prediction approaches 100%, the simulated target is identifiable from the active feedback.

If many candidates remain, the pretraining feedback did not uniquely identify the hidden state. Increase the number or quality of pretraining observations.

If exact prediction fails when `deployment drift` or `unmodelled stochastic drift` is enabled, that is the expected result. The best predictor can only identify and roll forward structure that exists in the model.

## Engineering Interpretation

For a real Bluetooth system, this simulator says:

- Exact-hop prediction requires recovering the real hop-selection state, not just learning channel density.
- A generic neural network is not automatically optimal; it must implicitly solve the same hidden-state identification problem.
- Active feedback is valuable because it can reduce uncertainty before deployment.
- If the real hop process is cryptographically keyed, clocked, adaptive, or affected by unknown state that the learner cannot observe, exact prediction remains impossible no matter how much compute is available.

So the infinite-resource answer is:

```text
Bayesian system identification with active feedback, followed by exact state rollout.
```

Everything else is an approximation to that method.
