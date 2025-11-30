using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

public class ConnectionPool
{
    private readonly ConcurrentQueue<Connection> _availableConnections;
    private readonly ConcurrentDictionary<string, Connection> _activeConnections;
    private readonly int _maxPoolSize;
    private readonly int _minPoolSize;
    private readonly string _provider;
    private int _currentPoolSize;
    private readonly object _lock = new object();

    public ConnectionPool(string provider, int minSize = 2, int maxSize = 10)
    {
        _provider = provider;
        _minPoolSize = minSize;
        _maxPoolSize = maxSize;
        _availableConnections = new ConcurrentQueue<Connection>();
        _activeConnections = new ConcurrentDictionary<string, Connection>();
        _currentPoolSize = 0;
        // Initialise minimum connections
        for (int i = 0; i < _minPoolSize; i++)
        {
            var connection = CreateConnection();
            _availableConnections.Enqueue(connection);
        }
    }

    public Connection AcquireConnection()
    {
        Connection connection;
        if (_availableConnections.TryDequeue(out connection))
        {
            if (connection.IsValid())
            {
                _activeConnections.TryAdd(connection.Id, connection);
                return connection;
            }
        }

        // No available connection or invalid, create new one if under limit
        lock (_lock)
        {
            if (_currentPoolSize < _maxPoolSize)
            {
                connection = CreateConnection();
                _activeConnections.TryAdd(connection.Id, connection);
                return connection;
            }
        }

        // Wait for available connection (simplified timeout)
        Thread.Sleep(1000);
        return AcquireConnection();
    }

    public void ReleaseConnection(Connection connection)
    {
        if (connection != null)
        {
            Connection removed;
            _activeConnections.TryRemove(connection.Id, out removed);
            if (connection.IsValid() && _availableConnections.Count < _maxPoolSize)
            {
                _availableConnections.Enqueue(connection);
            }
            else
            {
                connection.Dispose();
                Interlocked.Decrement(ref _currentPoolSize);
            }
        }
    }

    private Connection CreateConnection()
    {
        Interlocked.Increment(ref _currentPoolSize);
        return new Connection(_provider, Guid.NewGuid().ToString());
    }

    public ConnectionPoolStats GetStats()
    {
        return new ConnectionPoolStats
        {
            Provider = _provider,
            TotalConnections = _currentPoolSize,
            ActiveConnections = _activeConnections.Count,
            AvailableConnections = _availableConnections.Count,
            MaxPoolSize = _maxPoolSize,
            MinPoolSize = _minPoolSize
        };
    }
}

public class Connection : IDisposable
{
    public string Id { get; private set; }
    public string Provider { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime LastUsed { get; set; }
    public bool IsDisposed { get; private set; }

    public Connection(string provider, string id)
    {
        Provider = provider;
        Id = id;
        CreatedAt = DateTime.UtcNow;
        LastUsed = DateTime.UtcNow;
        IsDisposed = false;
    }

    public bool IsValid()
    {
        return !IsDisposed && (DateTime.UtcNow - CreatedAt).TotalMinutes < 30;
    }

    public void UpdateLastUsed()
    {
        LastUsed = DateTime.UtcNow;
    }

    public void Dispose()
    {
        IsDisposed = true;
    }
}

public class ConnectionPoolStats
{
    public string Provider { get; set; }
    public int TotalConnections { get; set; }
    public int ActiveConnections { get; set; }
    public int AvailableConnections { get; set; }
    public int MaxPoolSize { get; set; }
    public int MinPoolSize { get; set; }
}

public class AsyncOperationManager
{
    private readonly SemaphoreSlim _semaphore;
    private readonly int _maxConcurrency;

    public AsyncOperationManager(int maxConcurrency = 5)
    {
        _maxConcurrency = maxConcurrency;
        _semaphore = new SemaphoreSlim(maxConcurrency, maxConcurrency);
    }

    public async Task<T> ExecuteAsync<T>(Func<Task<T>> operation)
    {
        await _semaphore.WaitAsync();
        try
        {
            return await operation();
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public int AvailableSlots { get { return _semaphore.CurrentCount; } }
    public int MaxConcurrency { get { return _maxConcurrency; } }
}
