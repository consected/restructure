# This file re-opens Object, to add a 'global' instance method, #instance_var_init.
# The new method checks if the named instance variable already is defined. If it 
# is not, the variable is initialized with nil (the default), or a specified value
# This is basically just a shortcut to perform:
#
#   unless defined? @somevar
#     @somevar = nil
#   end
#
# Typically this will be called in a controller before_action, or model after_initialize
#
# For example:
#
#   model Foo
#     after_initialize :init_vars
#
#     def init_vars
#       instance_var_init :somevar
#       instance_var_init :someothervar
#     end
#   end
#
#   Note that if attempting to use after_initialize in a concern, be sure to name
#   the after_initialize (or before_action) method so that it does not override an
#   existing method in the class that includes the concern
#

class Object
  def instance_var_init var, o=nil
    varname = "@#{var}"
    unless instance_variable_defined?(varname)
      instance_variable_set(varname, o)
    end
  end
end
