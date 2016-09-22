# Landscape Turner

Landscape Turner is a set of two ruby scripts for backing up the Landscape service, `landscape-turner-backup` and `landscape-turner-restore`.

## License

Landscape Turner is MIT Licensed.

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

To override specific paths, use `-o name1=path1 name2=path2 name3=path3`. To disable specific paths for backup, use `-d name1 name2`. Overrides have higher priority than `--landscape-prefix`.

## Options for landscape-turner-restore

### -r, --restore-prefix=*string*
Prefix to prepend default landscape dirs (/var, /etc) with (default: nothing)

### -n, --no-db
Disable database restore


In addition to the optional arguments, you must specify exactly one .tar.gz file to restore.

## Install

You can build Landscape Turner from the gemspec file like so:

`$ gem build landscape-turner.gemspec`

`$ sudo gem install landscape-turner-1.5.0.gem`

If you don't want to build from the gemspec yourself, you can install from rubygems with `$ sudo gem install landscape-turner`
