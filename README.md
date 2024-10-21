# pinglog
Ping multiple ips and record them in the log by time.

## Support system

- Linux
- macOS

## Usage

#### Start

**Specific IP:**

```bash
sh pinglog.sh start <ip1> <ip2> <ip...>
```

**File:**

One line per IP.

```bash
sh pinglog.sh start <ips_file>
```

#### Stop

**Stop One:**

```bash
sh pinglog.sh stop <pids_file>
```

**Stop All:**

Stop the last run.

```bash
sh pinglog.sh stop
```

#### Script automatic

Stop first, and then run it with the ips file.

```bash
sh run.sh
```

## Tools

#### Summary

The statistical delay exceeds the value of the specified ms.

```bash
find . -name "$(date +"%Y%m%d")*.log" -type f | xargs grep -H "time=" | awk -F 'time=' '{if ($2 > 1) print $0}'
```