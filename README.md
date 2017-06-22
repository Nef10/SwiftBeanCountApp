#  SwiftBeanCount

## What

This project is a double-entry accounting software written in Swift 4. It is inspired by [beancount](http://furius.ca/beancount/) and therefore reads/writes [plain text accounting](http://plaintextaccounting.org) files.

## Why

I do this project in my spare time for different reasons:

  - Learn Swift
  - Learn native MacOS developement
  - Practice TDD

## Status

This project is in an early alpha stage, not even all parsing is working. Functionality working:

  - Parse transactions with data, flag, payee, narration and optional tags
  - Parse postings with account, amount and commodity
  - Parse account openings with optional commodity
  - Parse account closings
  - Parse comments and ignore them

Todos for parsing:

  - Parse balance checks
  - Parse cost in postings
  - Support tagstacks
  - Parse events
  - Parse prices
  - Parse commodity definitions
  - Parse notes
  - Parse metadata
  - Parse custom (and ignore)
  - Better error messages
  - Amount interpolation
  - Includes

Todos for checks:

  - Check transaction balance
  - Check account balance amount and account within account opening
  - Check account closing balance in zero
  - Check posting within account opening
  - Check commodity in account
  - Check accounts are in the main accounts
  - Inventory booking

Todos for internal structure:

  - Reflect account hierarchy + five main accounts

## Comparasion to beancout (of the features SwiftBeanCount currently implements)

### What SwiftBeanCount supports but beancount does not

  - Full unicode support
  - Commodities with more than 24 characters
  - Errors for lines with unknown syntax
  - Emtpy window
  - Requires payee and narration field
  - Only allows percision which without decimal point fits into UInt64

### What beancout supports but SwiftBeanCount does not

  - Fast parsing
  - Date with slashes instead of dashes
  - "txn" instead of * as ok flag
  - Flags on Postings
  - An optional pipe between payee and narration
  - Links
  - Pad
  - Documents
  - Queries
  - Command line tools
