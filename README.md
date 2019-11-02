# window-shortcuts

macOS only!
Get menu shortcuts by window owner name.

## Install

```
$ npm install window-shortcuts
```

## Usage

### Async

```js
import windowShortcuts from 'window-shortcuts'

windowShortcuts('iTerm2')
  .then(shortcuts => {
    console.log(shortcuts)
    /*
    [
      {
        "title": "Preferences...",
        "keys": [
          "Meta",
          ","
        ],
        "group": "iTerm2"
      },
      {
        "keys": [
          "Meta",
          "h",
        ],
        "title": "Hide iTerm2",
        "group": "iTerm2",
      },
      ...
    ]
    */
  })
  .catch(error => console.log(error))
```

### Sync

```js
const shortcuts = windowShortcuts.sync('iTerm2')
```
