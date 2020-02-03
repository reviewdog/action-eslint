# GitHub Action: Run eslint with reviewdog

[![Docker Image CI](https://github.com/reviewdog/action-eslint/workflows/Docker%20Image%20CI/badge.svg)](https://github.com/reviewdog/action-eslint/actions)
[![depup](https://github.com/reviewdog/action-eslint/workflows/depup/badge.svg)](https://github.com/reviewdog/action-eslint/actions?query=workflow%3Adepup)
[![release](https://github.com/reviewdog/action-eslint/workflows/release/badge.svg)](https://github.com/reviewdog/action-eslint/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/reviewdog/action-eslint?logo=github&sort=semver)](https://github.com/reviewdog/action-eslint/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

This action runs [eslint](https://github.com/eslint/eslint) with
[reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve
code review experience.

[![github-pr-check sample](https://user-images.githubusercontent.com/3797062/65439130-a6043b80-de61-11e9-98b5-bd9567e184b0.png)](https://github.com/reviewdog/action-eslint/pull/1)
[![github-pr-review sample](https://user-images.githubusercontent.com/3797062/65439073-91c03e80-de61-11e9-9077-39d480fbad0d.png)](https://github.com/reviewdog/action-eslint/pull/1)

## Inputs

### `github_token`

**Required**. Must be in form of `github_token: ${{ secrets.github_token }}`'.

### `level`

Optional. Report level for reviewdog [info,warning,error].
It's same as `-level` flag of reviewdog.

### `reporter`

Reporter of reviewdog command [github-pr-check,github-check,github-pr-review].
Default is github-pr-check.
It's same as `-reporter` flag of reviewdog.

github-pr-review can use Markdown and add a link to rule page in reviewdog reports.

### `eslint_flags`

Optional. Flags and args of eslint command. Default: '.'

### `working_directory`

Optional. The directory from which look for and run eslint. Default '.'

## Example usage

You also need to install [eslint](https://github.com/eslint/eslint).

```shell
# Example
$ npm install eslint -D
```

You can create [eslint
config](https://eslint.org/docs/user-guide/configuring)
and this action uses that config too.

### [.github/workflows/reviewdog.yml](.github/workflows/reviewdog.yml)

```yml
name: reviewdog
on: [pull_request]
jobs:
  eslint:
    name: runner / eslint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - name: eslint
        uses: reviewdog/action-eslint@v1
        with:
          github_token: ${{ secrets.github_token }}
          reporter: github-pr-review # Change reporter.
          eslint_flags: 'src/'
```
