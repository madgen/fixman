# fixman

code  :: https://github.com/madgen/fixman (url)

## DESCRIPTION:

THIS PROJECT IS NOT YET READY FOR USAGE!

A tool to test source code analysis command line tools against source code
remotely available in git repositories such as GitHub.

## FEATURES/PROBLEMS:

## COMMAND LINE

### test

`fixman <test>`

### list/shortlist

`fixman <list|shortlist>`

Lists the repositories used in testing. Shortlist succint summary
of the repositories with canonical name and commit hash used for
testing.

### add

`fixman <add>`
Starts interactive session to add new repository with the details.

### delete

`fixman <delete> <canonical_name>`

Delete the repository identified by its canonical name from the list of places
to be tested.

### fetch

`fixman <fetch> [group...]`

Download all the repositories belonging to list of groups. The groups would be
specified in the configuration file. If group is left out all repositories are
fetched.

The version of the repository fetch is set to HEAD by default. If a different
commit is desired this can be specified while adding the repository or by
altering the YAML file containing the repositories.

If the remote repository cannot be reached or there are not sufficient
priveleges, fetch process skips to the next repository but produces a
warning.

### update

`fixman <update> <canonical_name> [commit_SHA]`

Updates the commit of the repository. This can be a future commit or an older
one. It only updates the repository listing as such `upgrade` needs to be run to
update the repo in the file system.

### upgrade

`fixman <upgrade> <group(s)>`

## CONFIGURATION FILE

Configuration file is a YAML file ordinarily located at `.fixman_conf.yaml`
unless it has been overridden by the `-c` command line option. It contains
task definitions, base path for the fixtures, and allows overriding various
defaults.

### Fixture base (compulsory)

The base path for repositories listed in the ledger.

Example

```
:fixture_base: /path/to/base_dir
```

### Task definitions (compulsory)

An array of tasks to be run on the repositories specified in the fixtures
ledger.

Example:

```
:tasks:
  - :target_condition: :ruby: 2.even?
    :command:
    :extra_placeholders:
    :cleanups:
    :target_placeholder:
```

### Extra repository information (optional)

If set, it causes `add` command to direct more queries to the user than what
is necessary for fixman to function. This information can be things like notes,
licence, urls, and anything else. It further allows these fields to be optional,
chosen from set values, or mandatory.

Each extra repository information has the following subfields

#### Symbol (mandatory)
Unique symbol for the extra bit of information.

#### Prompt (mandatory)
Prompt directed at the user when `add` command is used.

#### Label (mandatory)
Label to be used when the repositories are listed for this information.

#### Choices (optional)
A list of strings corresponding to choices the value of the field can take.

#### Optional (optional)
If set to true, then the empty entry is acceptable. If omitted or set to false
the prompt is repeated until a valid input is received.

Example:

```
:extra_repo_info:
  - :symbol:    licence
    :prompt:    Please enter licence
    :label:     Licence
    :choices:   [MIT, Apache, GPL]

  - :symbol:    notes
    :prompt:    Any notes?
    :label:     Notes
    :optional:  true
```

### Groups (optional)

Not every repository in the ledger needs to be fetched and tested. This option
allows user to specify groups which can be separately fetched and tested. Refer
to the command line documentation for example usage.

Example:

```
:groups: [:public, :private]
```

### Fixture ledger (optional)

The path to the YAML file that acts as a ledger for the repositories. Defaults
to `.fixman_ledger.yaml`.

Example:

```
:fixture_ledger: /path/to/my_ledger.yaml
```

## REQUIREMENTS:

Requires Ruby 1.9.3 or onwards.

## INSTALL:

`gem install fixman`

## LICENSE

Refer to LICENCE file but it is basically Apache Licence v2.0.

Copyright 2015 Mistral Contrastin
