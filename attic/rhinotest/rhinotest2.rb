require 'java'
require 'rhino/js.jar'

Javascript = Java.OrgMozillaJavascript

cx = Javascript.Context.enter
begin
    scope = cx.initStandardObjects

    # Maak een variabele "y" met daarin een string "hallo wereld":
    y = Javascript.Context.javaToJS "hallo wereld", scope
    # en maak die variabele beschikbaar aan de javascript sandbox:
    Javascript.ScriptableObject.putProperty scope, "y", y

    # Deze javascript gaan we uitvoeren:
    s = 'x = y;  function f(param) { return "hallo " + param; };'

    # Now evaluate the string we've collected. We'll ignore the result.
    cx.evaluateString scope, s, "<cmd>", 1, nil

    # Print the value of variable "x"
    x = scope.get "x", scope
    if x == Javascript.Scriptable.NOT_FOUND
        puts "x is not defined."
    else
        puts "x = " + Javascript.Context.toString(x)
    end

    # Call function "f('my arg')" and print its result.
    fObj = scope.get "f", scope
    if ! fObj.kind_of? Javascript.Function
        puts "f is undefined or not a function."
    else
        functionArgs = [ "wereld" ].to_java
        #f = (Function)fObj;
        result = fObj.call cx, scope, scope, functionArgs
        report = "f('wereld') = " + Javascript.Context.toString(result)
        puts report
    end
ensure
    Javascript.Context.exit
end
