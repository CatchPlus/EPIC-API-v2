require 'java'
require 'rhino/js.jar'

Javascript = Java.OrgMozillaJavascript


# // Creates and enters a Context. The Context stores information
# // about the execution environment of a script.
# Context cx = Context.enter();
cx = Javascript.Context.enter

# try {
begin
  # // Initialize the standard objects (Object, Function, etc.)
  # // This must be done before scripts can be executed. Returns
  # // a scope object that we use in later calls.
  # Scriptable scope = cx.initStandardObjects();
  scope = cx.initStandardObjects
  # // Collect the arguments into a single string.
  # String s = "";
  # for (int i=0; i < args.length; i++) {
  #   s += args[i];
  # }
  s = '"hello world!";'
  # // Now evaluate the string we've colected.
  # Object result = cx.evaluateString(scope, s, "<cmd>", 1, null);
  result = cx.evaluateString scope, s, "<cmd>", 1, nil
  # // Convert the result to a string and print it.
  # System.err.println(Context.toString(result));
  puts Javascript.Context.toString(result)
# } finally {
ensure
  # // Exit from the context.
  # Context.exit();
  Javascript.Context.exit
# }
end
