# buffet package

Buffer switcher

**This package is under construction.**

Keep ALT pressed while choosing. Releasing ALT will confirm selection.

```cson
'atom-workspace':
    'alt-s': 'buffet:toggle'

'.buffet':

    'alt-o': 'core:confirm'
    'alt-j': 'core:move-down'
    'alt-k': 'core:move-up'
    'alt-d': 'buffet:close-buffer'

    'alt-s': 'buffet:previous'
    'alt-escape': 'core:cancel'
```
