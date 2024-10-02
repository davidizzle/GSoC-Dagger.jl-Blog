# GSoC Blog

### 1.1 Dagger.jl Recap

#### *Parallelism Made Easy*

![image](logo.jpg)

It is typically a cumbersome exercise, for programmers, to quickly and efficiently deploy multithreaded, distributed, or GPU computation.

Doing all three at once is then certainly no easy feat — but that is where [Dagger.jl](https://github.com/JuliaParallel/Dagger.jl) swoops in!

Dagger is a Julia module that brings all three together and makes parallelism easy for the user — it acts as a unified task interface and aims to solve difficult problems such as:

- Cross-task dependency/synchronization
- Abstracting computation across servers, threads, and GPUs
- Dynamic workload balancing
- Automating data transfer and worker migration, while hiding latency
- Automating GPU utilization and data conversion

As a result, though the user might even be agnostic to concurrency and parallelism, leveraging Dagger's API she is able to tinker with high performance computing — *in seconds*.

### 1.2 Our proposed objectives

#### *Enter: DAGs*

Dagger has recently been incorporating streaming functionality in its `jps/stream2` branch, which allows users to implement task DAGs through a streaming queue of tasks. Again, these *streaming* tasks can then seamlessly be deployed in a multi-threaded, multi-process fashion which can also leverage a heterogeneous set of computing resources.

At the beginning of this contribution program, we set some ambitious goals:

1. **Tooling for Task Execution Validation**: we aimed to develop tools to ensure tasks execute with minimal memory allocation, which enhances performance by avoiding garbage
2. 



## Building a Streaming Testset

To gain more confidence in the robustness, effectiveness, and versatility of streaming tasks, a comprehensive collection of tests was written during the first few weeks.

These included many possible combinations for DAGs — namely single infinite or finite tasks, multiple configurations of tasks (2 → 1, 1 → 2, diamond as per figure below), which were spawned themselves on combinations of different threads and workers.

Afterward, the allocation of task streams was also gauged to earn more confidence around `stream.jl`’s ability to not require further allocation — effectively slowing down performance, increasing the number of calls for garbage collection, and adding overhead.

`stream.jl` ultimately passes all tests, which earned the developers enough confidence to merge it with the main branch.

---
## Testing Networking Protocols

Given the desire to build Dagger’s streaming functionality towards heterogeneous computing and highly performing network communication, several networking protocols were tested.

Workers were able to communicate over the wire through Julia’s built-in TCP and UDP libraries effectively — with scripts testing transmission of singular and vectors of `Float64` values, respectively.

For MQTT and NATS — popular message queue protocols, one often used in IoT and the latter in microservices for its lightweight nature — libraries were sourced within the Julia community, respectively employing [Mosquitto.jl](https://github.com/denglerchr/Mosquitzto.jl) and [NATS.jl](https://github.com/jakubwro/NATS.jl). Message queues work with a pub/sub system, where certain workers publish to a message queue, and only the workers subscribed to the same queue receive the data — in this case, a single publisher was tested to publish single and vectors of `Float64` values, with a single subscriber successfully pulling the data from the message queue.

### Application to Streaming Tasks and Buffers

---

## Memory-Mapped Ring Buffer Rollout

Through the Mmap library, which helps with memory-mapping of files, a new type of buffer was implemented in the following couple of weeks — an `mmapRingBuffer`, i.e., a ring buffer mapping data on disk. The rationale behind a memory-mapped ring buffer is to eliminate the overhead from allocations of extra space when copying buffer data, but rather having a downstream task in a DAG access the same memory used by the upstream’s ring buffer.

![image](juliacon.jpg "JuliaCon Eindhoven 2024")