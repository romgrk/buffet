
_      = require 'underscore-plus'
Path   = require 'path'

{$, $$, View}         = require 'atom-space-pen-views'
{CompositeDisposable} = require 'event-kit'

ws = atom.workspace

config = (k) -> atom.config.get 'buffet.'+k

module.exports =
class BuffetView extends View
    buffet: null
    panel: null
    panelView: null
    animationDelay: 300

    @content: ->
        @div class: 'buffet transform', tabindex: -1, =>
            @div class: 'select-list', =>
                @ol class: 'list-group', tabindex: -1, outlet: 'list'

    initialize: (buffet) ->
        @addClass 'buffet'

        @buffet = buffet

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add @element,
            'core:move-up':         => @moveUp()
            'core:move-down':       => @moveDown()
            'core:confirm':         => @confirm()
            'core:cancel':          => @hide()
            'buffet:previous':      => @openPreviousBuffer()
            'buffet:close-buffer':  => @closeActiveBuffer()

        @attachEventListeners()

    attachEventListeners: ->
        @blur       => @hide()
        if config('switchOnReleaseAlt')
            @keyup (e)  => @confirm() if e.keyCode == 18

    attach: ->
        @panel = atom.workspace.addModalPanel(item: this, visible: false)
        @panelView = $(atom.views.getView(@panel))
        @panelView.removeClass 'from-top'
        @panelView.addClass 'buffet-panel transform'

    detach: ->
        @panel?.destroy()
        @panel = null

    hide: ->
        return unless @isVisible()
        @restoreFocus()
        @addClass 'transform'
        @panelView.addClass 'transform'
        setTimeout @hidePanel, @animationDelay

    hidePanel:  =>
        @list.empty()
        @panel.hide()

    show: ->
        @attach() unless @panel?
        @storeFocusedElement()
        @populateList()
        @panel.visible = true
        @panelView.show()
        @removeClass 'transform'
        @panelView.removeClass 'transform'
        @focus()

    populateList: ->
        @buffers = atom.project.getBuffers()
        _.each @buffers, (b) =>
            if !@isCurrent(b)
                @list.append @viewForItem(b)
        @index = 0
        @items = _.map @list.find('li.buffer-item'), $
        if @items? and @items.length isnt 0
            @items[@index].addClass 'selected'

    viewForItem: (item) ->
        item.alternate = @getAlternateToken item
        $$ ->
            @li class: 'buffer-item ' + item.alternate, 'data-item-uri': item.getUri(), =>
                @div class: 'icon icon-file-text primary-line', 'data-name': item.getBaseName(), item.getBaseName()
                @div class: 'secondary-line', Path.dirname(
                    require('./buffet').humanPath item.getPath())

################################################################################
# Section: Buffet utils
################################################################################

    getActiveItem: ->
        @list.find('.selected')

    getActiveItemPath: ->
        @list.find('.selected').data 'item-uri'

################################################################################
# Section: Event handlers
################################################################################

    openPreviousBuffer: =>
        return unless @buffet.previous?
        ws.open @buffet.previous
        @hide()

    closeActiveBuffer: =>
        activeItem = @getActiveItem()
        activePath = @getActiveItemPath()

        pane = atom.workspace.getActivePane()
        editor = pane.itemForURI(activePath)
        pane.destroyItem(editor)

        # Item removal animation
        if @items.length == 0
            @hide()
        else
            @moveDown()
            activeItem.addClass 'closing'
            setTimeout(->
                activeItem.remove()
            , @animationDelay)

    moveUp: ->
        @items[@index].removeClass 'selected'
        @index = if @index - 1 < 0 then @items.length-1 else @index - 1
        @items[@index].addClass 'selected'

    moveDown: ->
        @items[@index].removeClass 'selected'
        @index = if @index + 1 >= @items.length then 0 else @index + 1
        @items[@index].addClass 'selected'

    confirm: =>
        ws.open @list.find('.selected').data 'item-uri'
        @hide()

################################################################################
# Section: Helpers
################################################################################

    storeFocusedElement: ->
        @previouslyFocusedElement = $(document.activeElement)

    restoreFocus: ->
        @previouslyFocusedElement?.focus()

    serialize: ->

    destroy: ->
        @element.remove()

    getElement: ->
        @element

    isVisible: ->
        (@panel? && @panel.isVisible())

    getAlternateToken: (buffer) ->
        if buffer.getUri() == @buffet.previous
            'alternate'
        else
            ''

    isCurrent: (buffer) ->
        buffer.getUri() == atom.workspace.getActiveEditor().buffer.getUri()

    isPrevious: (buffer) ->
        buffer.getUri() == @buffet.previous
