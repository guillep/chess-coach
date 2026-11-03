# How to build a Mamotreto app

Mamotreto is the shell that Chessmate and La Pulpería share: a window with a
title bar and a notification bell, pages in a tab rail on the left, and a
status line. This guide collects the rules those apps follow, so that a new app
looks and behaves like the others.

## 1. Layout of a list page

Most pages list things and act on them. Build them on `MMListPage`:

- **The list is on the left, and it is big.** The filters go above it, as
  dropdowns, and flow onto more lines when they don't fit. The list or table
  takes all the room left.
- **The pane is on the right, with a fixed width** (`MMListPage paneWidth`, 340 px).
  It shows what is selected, and nothing else.
- **The pane's actions are on top.** They act on the selection: Bulk close,
  Send comment, Read failing tests.
- **Tabs go below the actions** when there is a lot to show. Integrate has
  Overview, CI and Comment.
- **Confirmations replace the tabs in the pane**, for example "Close 2 items?".
  They keep the same actions above. `showInPane:` shows one, and `refreshPane`
  brings the tabs back.
- **Buttons that change the selection itself go above the list**, not in the
  pane. Select all and Clear selection are examples.

Pages built around a board (Chessmate's review and coach pages) are exceptions:
the board is what is big on the left, with its own controls.

## 2. Buttons, links and filters

- **Buttons never appear or disappear.** A button is either always there,
  disabled until it applies and then enabled, or it is not on the page at all.
  Add the pane's actions once with `addAction:`, and enable or disable them as
  the selection changes.
- **A link is a link, and a button is a button.**
  - An external destination, such as a GitHub page or a CI run, is a link
    (`MMWidgets link:to:`).
  - An action inside the app is a button (`ToButton`).
  - Never use a label with a click handler.
- **Filters are dropdowns** (or other selection widgets), never buttons. The
  first entry says what the dropdown filters, and each entry can say how many
  items it holds.
- **Keep links out of list rows**, where they get clicked by accident while
  selecting. Put them in the pane.

## 3. Concurrency

Use as little as possible.

- **An app has one background process**, its session's `MMScheduler`. It runs
  the periodic checks when they are due, then the work given to
  `whenWokenDo:`, such as a task manager's queued jobs. Then it sleeps until
  the next check or until someone signals its `wakeup` semaphore.
- **Nothing else forks:** not the UI, not the session, not the clients. Queue
  I/O as jobs. UI code goes back to the UI thread only through the space's
  `enqueueTask:` (`MMWindow>>inUIDo:`).
- **A job is the unit that is never cut.** Work whose requests must not be
  separated, such as commenting and closing, goes in one job.
- **Closing the window asks first while jobs are queued or running.** The
  choices are Wait, or Close and stop them (`MMSpace`, `MMWindow>>closeRequestedIn:`).
  Closing lets the running job finish, then ends the process.
- **A test checks that nothing is left running.** Starting and shutting down
  the session leaves the same processes as before.
- **Background work never redraws a page.** Redrawing behind the user's back
  loses the selection, and the table may still deliver selection events for
  the rows it had. When what a page shows effectively changed, the session
  announces it once; the window then shows **Updates available** at the top
  right, and only a click on it redraws the page (`MMWindow>>showUpdatesAvailable`,
  `whenRefreshedDo:`). Nothing changed, nothing shown: compare what the pages
  show, without timestamps or ETags, before announcing.
- **What the user asked for is shown at once.** When the change comes from
  work the user asked for (Refresh, Bulk close, Send comment, Read failing
  tests), the announcement says so and the page is redrawn directly.

## 4. Network

- **Ask only when needed.** Use conditional requests (ETags), so that an
  unchanged answer costs nothing.
- **Make costly sweeps configurable.** Checking the CI of every open pull
  request costs three requests per pull request. It runs never, or every 1 to
  24 hours (2 by default), and only for those not checked within that time.
- **What the user is looking at may be refreshed on demand.** For example,
  selecting a pull request whose CI was checked more than 10 minutes ago asks
  again, for that one only.
- **Services behind a firewall are asked only when the user clicks**, one
  thing at a time, with a pause between requests. Jenkins on ci.inria.fr blocks
  clients that send too many requests.

## 5. Notifications

- **Notifications are posted to the session** (`MMNotifications post:`). A new
  notification with the same key replaces the previous one, so a job that
  reports twice shows once.
- **The bell's list never takes more than 70 % of the window's height.**
  Beyond that it scrolls.
- **Clear all is always at the bottom**, and is disabled when there is nothing
  to clear.
- **Only the newest 50 are kept.**

## 6. Files

- **Every saved format carries a version.** A new field bumps the version, and
  a file without the field gets its default.
- **Never write the same object twice in one STON file**, because STONJSON
  refuses shared references. Use `Array new` for empty defaults instead of
  `#()`, and copy arrays when writing.
