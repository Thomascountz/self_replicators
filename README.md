# Self Replicators

This is an experimental project inspired by the paper "[Computational life: How well-formed, self-replicating programs emerge from simple interaction](https://arxiv.org/abs/2406.19108)" from researchers, Alakuijala, Jyrki, et al. (2024).

The goal of the experiment is to observe the spontaneous emergence of self-replicating programs described in the paper.

In most artificial life simulations, forcing functions, like mutation and selection, are applied to evolve complexity or even seed the system with known replicators.

In this paper however, the researchers produced a system where self-replicating programs can emerge spontaneously, without any explicit selection pressure.

The goal of this project is to replicate their findings in a simplified environment, and deepen their analysis by applying structural analysis techniques borrowed from the field of computer language development.

## Roadmap

### Phase 1: Build the Core Engine

- [X] Implement BFF Interpreter
  - Parse the 10 valid instructions (`<`, `>`, `{`, `}`, `+`, `-`, `.`, `,`, `[`, `]`).
  - Manage state: instruction pointer, `head0`, `head1`, and the byte tape.
  - Verification: Create unit tests with simple, known programs to ensure correctness.

- [ ] Implement Sequitur Algorithm
  - Build the core logic for inferring a context-free grammar from a sequence.
  - Key components: digram hash, rule list, symbol replacement loop.
  - Verification: Test with known strings (`abcabcabc`) to confirm it produces the expected minimal grammar.

- [ ] Implement Structural Analysis Metrics
  - Create a function that takes a Sequitur grammar as input.
  - It should calculate and return:
    - `Structural Entropy Score`: `1 - (GrammarSize / OriginalStringLength)`
    - `Rule Count`: Total number of rules.
    - `Rule Usage Frequencies`: A hash map of `{RuleName => Count}`.
    - `Max Hierarchy Depth`: The deepest level of rule nesting.

### Phase 2: Construct the Experiment & Data Pipeline

- [ ] Build the Simulation Loop
  - Initialize the "primordial soup" (e.g., 2¹⁷ tapes of 64 random bytes).
  - Implement the main epoch loop: pair tapes, run the BFF interpreter, update tapes.
  - This is the "hot loop"; keep it lean and fast.

- [ ] Implement the Snapshotter
  - At the end of each epoch, the -only- task is to save the state.
  - Concatenate all tapes into a single master string (8MB).
  - Save this string to a compressed file (`epoch_XXXX.bin.gz`) in a dedicated queue directory.

- [ ] Design the SQLite Database
  - Create a single `results.sqlite3` file.
  - Define the schema with three tables:
    1.  `runs`: To track experiment parameters (`run_id`, `mutation_rate`, etc.).
    2.  `epochs`: To store the quantitative metrics per epoch (`epoch_number`, `structural_entropy`, `rule_count`).
    3.  `rules`: To store the "genes" (`epoch_id`, `rule_name`, `rule_definition`, `usage_count`).

### Phase 3: Run Analysis

- [ ] Create the Asynchronous Analyzer Script
  - This is a separate process that runs in parallel to the simulator.
  - It watches the snapshot queue directory.
  - Workflow:
    1.  Finds a new snapshot file.
    2.  Loads the 8MB string.
    3.  Runs the (slow) Sequitur algorithm.
    4.  Calculates the structural analysis metrics.
    5.  Writes the results to the `epochs` and `rules` tables in SQLite.
    6.  Deletes/archives the processed snapshot file.

- [ ] Develop Visualization & Querying Tools
  - Create a script to query the SQLite database.
  - Generate key plots to monitor the experiment in real-time or post-hoc:
    - The "EKG": `Structural Entropy vs. Epoch`.
    - The "Census": `Number of Rules vs. Epoch`.
    - The "Top Genes": A bar chart of the most frequent rules for a given epoch.

- [ ] Interpret the Results
  - Identify the state transition by finding the sharp rise in the Structural Entropy plot.
  - Query the `rules` table at that critical epoch to find the "winning" replicator's genetic code.
  - Track the population dynamics of different rules over time to observe competition, extinction, and the evolution of complexity.
