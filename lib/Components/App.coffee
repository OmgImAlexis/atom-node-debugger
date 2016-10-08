hg = require 'mercury'
h = hg.h

stepButton = require './StepButton'
breakpointPanel = require './BreakPointPane'
callstackPaneModule = require './CallStackPane'
consolePane = require './ConsolePane'
cancelButton = require './CancelButton'
dragHandler = require './drag-handler'
logger = require '../logger'

StepButton = null
BreakPointPane = null

LeftSidePane = (ConsolePane, state) ->
  h('div', {
    style: {
      display: 'flex'
      flex: 'auto'
      flexDirection: 'column'
    }
  }, [
    ConsolePane.render(state.logger)
  ])

RightSidePane = (BreakPointPane, CallStackPane, LocalsPane, WatchPane, StepButton, state) ->
  h('div', {
    style: {
      display: 'flex'
      flex: 1
      width: "#{state.sideWidth}px"
      flexBasis: "#{state.sideWidth}px"
      height: "#{state.height}px"
      flexDirection: 'row'
    }
  }, [
    h('div.inset-panel', {
      style: {
        flexDirection: 'column'
        display: 'flex'
        flex: 'auto'
      }
    }, [
      h('div.debugger-panel-heading', {
        style: {
          'flex-shrink': 0
        }
      }, [
        h('div.btn-group', {}, [
          StepButton.render(state.steps.stepContinue)
          StepButton.render(state.steps.stepNext)
          StepButton.render(state.steps.stepIn)
          StepButton.render(state.steps.stepOut)
          cancelButton.render(state.cancel)
        ])
      ])
      h('div.panel-body', {
        style: {
          flex: 'auto'
          display: 'list-item'
          overflow: 'auto';
        }
      }, [
        BreakPointPane.render(state.breakpoints)
        CallStackPane.render(state.callstack)
        LocalsPane.render(state.locals)
        WatchPane.render(state.watch)
      ])
    ])
  ])

exports.startBottom = (root, _debugger) ->
  ConsolePane = consolePane.create(_debugger)

  changeHeight = (state, data) ->
    state.height.set(data.height)

  toggleCollapsed = (state, data) ->
    console.log("toggle " + state.collapsed())
    state.collapsed.set(!state.collapsed())

  App = ->
    define = {
      height: hg.value 350
      collapsed: hg.value false
      channels: {
        changeHeight: changeHeight
        toggleCollapsed: toggleCollapsed
      }
      logger: ConsolePane()
    }
    hg.state(define)

  App.render = (state) ->
    h('div', {
      style: {
        display: 'flex'
        flex: 'auto'
        flexDirection: 'column'
        position: 'relative'
        height: "#{if state.collapsed then 10 else state.height}px"
      }
    }, [
      h('div.resizer', {
        style:
          cursor: if state.collapsed then '' else 'ns-resize'
          display: 'flex'
          'flex-direction': 'column'
        'ev-mousedown': dragHandler state.channels.changeHeight, {}
      }, [
        h('div', {
            style: {
              'align-self': 'center'
              cursor: 'pointer'
              'margin-top': '-4px'
              'margin-bottom':'-2px'
            }
            'ev-click': hg.send state.channels.toggleCollapsed
            className: if state.collapsed then 'icon-triangle-up' else 'icon-triangle-down'
          }, [
        ])
      ])
      h('div', {
        style: {
          display: 'flex'
          flex: 'auto'
          flexDirection: 'row'
        }
      }, [
        LeftSidePane(ConsolePane, state)
      ])
    ])

  hg.app(root, App(), App.render)

exports.startRight = (root, _debugger) ->
  StepButton = stepButton.StepButton(_debugger)
  BreakPointPane = breakpointPanel.create(_debugger)
  {CallStackPane, LocalsPane, WatchPane} = callstackPaneModule.create(_debugger)
  ConsolePane = consolePane.create(_debugger)

  changeWidth = (state, data) ->
    state.sideWidth.set(data.sideWidth)

  toggleCollapsed = (state, data) ->

  App = ->
    stepContinue = StepButton('continue', 'continue')
    stepIn = StepButton('step in', 'in')
    stepOut = StepButton('step out', 'out')
    stepNext = StepButton('step next', 'next')

    define = {
      sideWidth: hg.value 400
      channels: {
        changeWidth: changeWidth
      }
      steps: {
        stepIn: stepIn
        stepOut: stepOut
        stepNext: stepNext
        stepContinue: stepContinue
      }
      breakpoints: BreakPointPane()
      callstack: CallStackPane()
      watch: WatchPane()
      locals: LocalsPane()
      cancel: cancelButton.create(_debugger)
    }
    hg.state(define)

  App.render = (state) ->
    h('div', {
      style: {
        display: 'flex'
        flexDirection: 'row'
        'justify-content': 'center'
      }
    }, [
      h('div.resizer', {
        style:
          width: '5px'
          cursor: 'ew-resize'
        'ev-mousedown': dragHandler state.channels.changeWidth, {}
      })
      RightSidePane(BreakPointPane, CallStackPane, LocalsPane, WatchPane, StepButton, state)
    ])

  hg.app(root, App(), App.render)

exports.stop = ->
  BreakPointPane.cleanup()
  callstackPaneModule.cleanup()
