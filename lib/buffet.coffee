
_    = window.require 'underscore-plus'
fs   = require 'fs'
Path = require 'path'
CSON = require 'season'
# File = require 'file.js'

{CompositeDisposable} = window.require 'event-kit'
{TextEditor, File}    = require 'atom'
{$}                   = window.require 'atom-space-pen-views'

BuffetView = require './buffet-view'

Config =
    set: (k, v) -> atom.config.set 'buffet.'+k, v
    get: (k) -> atom.config.get 'buffet.'+k

config = (k) -> atom.config.get 'buffet.'+k
log = console.log.bind console

ws = atom.workspace
pr = atom.project

# TODO: have a stable order for buffers

module.exports = Buffet =
    buffetView: null
    subscriptions: null

    dataFile: null
    data: null

    models:
        data:
            projects:
                'default': {files: [], dirs: []}
        project:
            'default': {files: [], dirs: []}

    # Config object
    config:
        dataPath:
            type: 'string'
            default: process.env.HOME + '/.atom/storage/buffet.cson'
        switchOnReleaseAlt:
            type: "boolean"
            default: true

    activate: (state) ->
        @buffetView    = new BuffetView(@)
        @subscriptions = new CompositeDisposable
        @data          = @loadCSON()

        @subscriptions.add atom.commands.add 'atom-workspace',
            'buffet:toggle': => @toggle()

        # @subscriptions.add ws.onDidChangeActivePaneItem -> console.log "ok"
        @subscriptions.add ws.onDidChangeActivePaneItem @activePaneChanged.bind(@)

        # @subscriptions.add ws.onDidOpen @bufferOpened.bind(@)

        window.buffet = @

    activePaneChanged: (item) ->
        return unless item instanceof TextEditor
        @previous = @current
        @current = atom.workspace.getActiveTextEditor().getBuffer().getUri()
        # if @data[@cwd()]?[@current]?
        #     @data[@cwd()][@current] += 1
        # else
        #     @data[@cwd()][@current] = 1

    toggle: ->
        if @buffetView.isVisible()
            @buffetView.hide()
        else
            @buffetView.show()

    deactivate: ->
        @saveCSON()
        @subscriptions.dispose()
        @buffetView.destroy()

    serialize: -> buffetViewState: @buffetView.serialize()

    loadCSON: () ->
        try
            @data = CSON.readFileSync config('dataPath')
        catch e
            @data = $.extend({}, @models.data)
            console.log e
            @saveCSON()
            @data

    saveCSON: () ->
        try
            CSON.writeFileSync config('dataPath'), @data
        catch error
            console.error error

    ###
    Section: path utils
    ###

    cwd: ->
        atom.project.getPaths()[0]

    relative: (path) ->
        return Path.relative atom.project.getPath(), path

    relativeToHome: (path) ->
        return Path.relative process.env.HOME, path

    relativeDirname: (path) ->
        return Path.dirname Path.relative pr.getPath(), path

    absolute: (path) ->
        Path.resolve pr.getPath(), path

    # Get the more readable path: relative, relative to home, absolute
    #
    # * `path` the absolute path
    #
    # Returns {string} the path
    humanPath: (path) ->
        humanPath = @relative path
        return humanPath unless humanPath.indexOf('..') == 0
        humanPath = @relativeToHome path
        return '~/' + humanPath unless humanPath.indexOf('..') == 0
        return path

    humanDirPath: (path) ->
        Path.dirname @humanPath path
