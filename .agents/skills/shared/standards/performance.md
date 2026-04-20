# DevFlow Engineering Standards: Performance

Apply these principles to all code you design, generate, or review.

## 1. Algorithmic Efficiency
- **What:** The choice of algorithm and data structure determines the scalability ceiling.
- **DO:** Choose data structures and algorithms appropriate to the scale. Consider time and space complexity for every loop and collection operation.
- **DON'T:** Use O(n²) or worse solutions when an O(n log n) or O(n) alternative exists at comparable implementation complexity.

## 2. Database Access
- **What:** Database round-trips are the most common performance bottleneck.
- **DO:** Use indexed queries, paginate large result sets, and prefer batch operations over row-by-row processing.
- **DON'T:** Execute database queries inside loops (N+1 problem) or fetch entire tables when only a subset is needed.

## 3. Caching
- **What:** Caching trades memory for speed — use it strategically on proven hot paths.
- **DO:** Cache expensive computations, external API calls, and frequently-read, rarely-changed data at the appropriate layer (CDN, app, DB).
- **DON'T:** Cache mutable state without an explicit invalidation strategy, or cache at every level without measuring the hit rate.

## 4. Asynchronous Operations
- **What:** Blocking I/O wastes threads and degrades throughput under load.
- **DO:** Use async/non-blocking patterns for all I/O-bound operations (network, disk, database).
- **DON'T:** Block the main thread or event loop with synchronous I/O in environments where async is available.

## 5. Resource Management
- **What:** Leaked resources accumulate and eventually cause failures.
- **DO:** Release resources explicitly (connections, file handles, streams) after use. Use connection pooling for databases and HTTP clients.
- **DON'T:** Create new connections per request or leave resources open indefinitely.

## 6. Measure Before Optimizing
- **What:** Premature optimization wastes time and reduces readability.
- **DO:** Profile and measure first. Fix proven bottlenecks with data, not intuition.
- **DON'T:** Optimize code that is not on the hot path — prioritize correctness and readability until performance is demonstrably insufficient.
