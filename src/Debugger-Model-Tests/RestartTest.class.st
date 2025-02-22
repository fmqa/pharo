Class {
	#name : #RestartTest,
	#superclass : #DebuggerTest,
	#category : #'Debugger-Model-Tests-Core'
}

{ #category : #tests }
RestartTest >> stepA1 [
	self stepA2.
]

{ #category : #tests }
RestartTest >> stepA2 [
	| a |
	a := 1.
	1+1.
	2+2.
]

{ #category : #tests }
RestartTest >> testRestartTestShouldKeepTestGreen [

	| testCaseForRestart failed finished |
	failed := false.
	finished := Semaphore new.

	testCaseForRestart := DebuggerTestCaseForRestartTest selector: #testPushingValuesOnActivation.
	testCaseForRestart setUp.
	self settingUpSessionAndProcessAndContextForBlock: [ 
		[ [testCaseForRestart testPushingValuesOnActivation]
				on: TestFailure do: [ failed := true ] ]
					ensure: [ finished signal ] ].
	
	[session interruptedContext selector = #testPushingValuesOnActivation]
		whileFalse: [ session stepInto ].
	session restart: session interruptedContext.
	session resume.

	finished wait.	
	self deny: failed
]

{ #category : #tests }
RestartTest >> testRestartTestShouldPushNewValuesToTheStack [

	| testCaseForRestart |
	testCaseForRestart := DebuggerTestCaseForRestartTest selector: #testPushingValuesOnActivation.
	testCaseForRestart setUp.
	self settingUpSessionAndProcessAndContextForBlock: [ 
		testCaseForRestart testPushingValuesOnActivation ].

	session stepInto.
	session restart: session interruptedContext.

	self assert: session interruptedContext top == testCaseForRestart testedValue.
]

{ #category : #tests }
RestartTest >> testStepRestartAndRestepTopContext [
	"Get the execution to a context on method stepA2.
	Step over in it to reach the end (and check that the temporary variable assignement works)
	Restart the context.
	Step over in it a to reach the end a second time (and check that the temporary variable assignement also worked the second time)
	"
	| node |
	self settingUpSessionAndProcessAndContextForBlock: [ self stepA1 ].
	[session interruptedContext method == (self class>>#stepA1)] 
		whileFalse: [ session stepInto ].
	
	session stepInto.

	"Check that the execution is at the 'a:=1' node of method stepA2"
	self assert: session interruptedContext method equals: self class >>#stepA2.
	node := self class >>#stepA2 sourceNodeForPC: session interruptedContext pc.
	self assert: node isAssignment.
	self assert: node variable name equals: #a.
	
	session stepOver.
	session stepOver.
	"Check that the value of the 'a' temporary variable in the stepA2 context is 1"
	self assert: (session interruptedContext tempNamed: #a) equals: 1.
	"Check that the execution is at the '2+2' node of the stepA2 context"
	self assert: session interruptedContext method equals: self class >>#stepA2.
	node := self class >>#stepA2 sourceNodeForPC: session interruptedContext pc.
	self assert: node isMessage.
	self assert: node receiver isLiteralNode.
	self assert: node selector equals: #+.
	
	session restart: session interruptedContext.
	"Check that the execution returned to the 'a:=1' node of method stepA2"
	self assert: session interruptedContext method equals: self class >>#stepA2.
	node := self class >>#stepA2 sourceNodeForPC: session interruptedContext pc.
	self assert: node isAssignment.
	self assert: node variable name equals: #a.
	
	session stepOver.
	session stepOver.
	"Check that the execution has returned to the '2+2' node of the stepA2 context"
	self assert: session interruptedContext method equals: self class >>#stepA2.
	node := self class >>#stepA2 sourceNodeForPC: session interruptedContext pc.
	self assert: node isMessage.
	self assert: node receiver isLiteralNode.
	self assert: node selector equals: #+.
	"Check that the value of the 'a' temporary variable in the stepA2 context is 1 again"
	self assert: (session interruptedContext tempNamed: #a) equals: 1.
]
