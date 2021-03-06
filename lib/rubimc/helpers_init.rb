#####################################################################
# Initialize user variables
# 
# RubimCode provide only static variables that mast be initialize
# This file contains helpers for use it direct in user code
# 
# Example:
# => integer :local_var
# => float :@global_var
#####################################################################

class RubimCode
	# Type of all available variables
	C_TYPES = ['int', 'float', 'double', 'bool', 'short', 'char']
end

# Common function, execute for initialize all type of variables
# type_cc - type of variable in C-code
# variables - list of variables for init
def RubimCode.init_vars(type_cc, *variables) 
	vars_cc = ""
	rubim_vars = []

	variables.each {|var|
		# ToDo - поиск уже объявленных переменных и выдача предупреждений

		if var.is_a? Hash # ToDo
			RubimCode.perror "Ошибка. В текущей версии нельзя назначать переменным значения при объявлении"
			# key = var.keys.first
			# instance_variable_set("@#{key.to_s}" , UserVariable.new("#{key.to_s}"))
			# vars_cc += "#{key.to_s}=#{var[key]}, "

		elsif var.is_a? Symbol
			var_str = var.to_s
			var_name = var_str.gsub(/^[@$]/, "")
			new_var = RubimCode::UserVariable.new("#{var_name}", type_cc)
			rubim_vars << new_var

			case var_str[0..1]
				when /$./ # define GLOBAL variable 
					RubimCode.perror "Ruby-like global variables are not supported yet. Use 'integer :@#{var_name}'"
				when /@@/ # define CLASS variable 
					RubimCode.perror "Ruby-like class variables are not supported yet. Use 'integer :@#{var_name}'"
				when /@./ # define INSTANCE variable (in C it defined as global - outside the 'main' function)
					RubimCode::Printer.instance_vars_cc << new_var
				else 	  # define LOCAL variable (in C it defined as local)
					RubimCode::Isolator.local_variables << var_name if RubimCode::Isolator.enabled
					vars_cc += "#{var_name}, "
			end
			
		else
			RubimCode.perror "Unknown type of parameters for helper #{__method__}"
		end
	}
	if rubim_vars.empty?
		RubimCode.perror "No variables for initialize"
	end
	unless vars_cc.empty?
		vars_cc.chomp!(", ")
		RubimCode.pout ("#{type_cc} #{vars_cc};")
	end

	if rubim_vars.count == 1
		return rubim_vars[0]
	else
		return rubim_vars
	end
end

def boolean(*variables)
	RubimCode.init_vars("bool", *variables)
end
alias :bool :boolean

def integer(*variables)
	RubimCode.init_vars("int", *variables)
end
alias :int :integer

def float(*variables)
	RubimCode.init_vars("float", *variables)
end

def double(*variables)
	RubimCode.init_vars("double", *variables)
end
###############################################################################
# NOTE! When add NEW TYPES, modify preprocessor: method 'add_binding_to_init' #
###############################################################################

# Work with arrays (not work at this moment)
def array_of_integer(var, size: nil)
	array(var, with: {type: :integer, size: size})
end

def array(var, with: {type: 'UserVariable', size: nil})
	with[:size] = with[:size].to_i
	with[:type] = with[:type].to_s
	if with[:size].nil? or with[:type].nil?
		RubimCode.perror "Необходимо указать параметры массива (напр.: with: {type: :float, size: n, ...})"
		return
	end

	user_class = with[:type]
	with[:type] = 'int' if with[:type] == 'integer'
	with[:type] = 'bool' if with[:type] == 'boolean'
	if (with[:type].in? RubimCode::C_TYPES) 
		user_class = "UserVariable"
	end

	arr = with[:size].times.map do |i| 
		eval("RubimCode::#{user_class}.new('#{var}[#{i}]', '#{with[:type]}')")
	end
	instance_variable_set("@#{var}", RubimCode::UserArray.new(arr))
	eval ("@#{var}.name = '#{var}'")
	eval ("@#{var}.type = \"#{with[:type]}\"")
	RubimCode.pout "#{with[:type]} #{var}[#{with[:size]}];"
end
