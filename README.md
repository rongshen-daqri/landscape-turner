# Landscape Turner

Landscape Turner is a set of two ruby scripts for backing up the Landscape service, 	`landscape-turner-backup` and `landscape-turner-restore` .

## General Usage

```bash
$ landscape-turner-backup --snapshot-path=/home/daqri/backup

$ landscape-turner-restore /home/daqri/backup.tar.gz
```

## Options for landscape-turner-backup

###-s, --snapshot-path=/path/to/snapshot
Required

###-o, --override=*string*
Override paths with -o name1=path1

### -d, --disable=*string*
Disable paths with -d name

### -n, --no-db
Disable database backup

### -l, --landscape-prefix=/path/to/default/dirs
Path to prefix default landscape dirs (/var, /etc), default is nothing.

### -p, --no-op
No-op (dry run)


To override specific paths, use `-o name1=path1 -o name2=path2 -o name3=path3`. To disable specific paths for backup, use `-d name1 -d name2`. Overrides have higher priority than `--landscape-prefix`.

## Options for landscape-turner-restore

### -r, --restore-prefix=*string*
Prefix to prepend default landscape dirs (/var, /etc) with (default: nothing)

### -n, --no-db
Disable database restore


In addition to the optional arguments, you must specify exactly one .tar.gz file to restore.
