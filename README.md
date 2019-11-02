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
        "mods": [
          "Meta"
        ],
        "char": ",",
        "group": "iTerm2"
      },
      {
        "mods": [
          "Meta"
        ],
        "title": "Hide iTerm2",
        "group": "iTerm2",
        "char": "h"
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
