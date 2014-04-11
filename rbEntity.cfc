/*
 * Any changes should be made and pushed to here: https://github.com/Prefinem/RedBeanCF
 * Author: William Giles
 * License: MIT http://opensource.org/licenses/MIT
 */

component {
	function init() {
		return this;
	}
	public function onMissingMethod(MissingMethodName, MissingMethodArguments){
		if(Find("set",arguments.MissingMethodName)){
			var key = Replace(arguments.MissingMethodName,"set","");
			return this._set(key,arguments.MissingMethodArguments[1]);
		}else if(Find("get",arguments.MissingMethodName)){
			var key = Replace(arguments.MissingMethodName,"get","");
			return this._get(key);
		}else if(Find("_own",arguments.MissingMethodName)){
			var component = Replace(arguments.MissingMethodName,"_own","");
			var referenceKey = len(trim(arguments.MissingMethodArguments[1])) ? arguments.MissingMethodArguments[1] : "";
			var referenceColumn = len(trim(arguments.MissingMethodArguments[2])) ? arguments.MissingMethodArguments[2] : "";
			return _own(component,referenceKey,referenceColumn);
		}else{
			throw (message="Missing Method", type="error");
		}
	}
	public function _export(keys=arrayNew(1)){
		var output = {};
		if(arrayLen(keys)>0){
			for(key in keys){
				output[key] = variables[key];
			}
		}else{
			for(key in variables){
				if(key != "THIS" && key != "KEY" && !isFunction(key)){
					if(IsInstanceOf(variables[key],"rb") || IsInstanceOf(variables[key],"#this.componentName#")){
						output[key] = variables[key]._export();
					}else if(isArray(variables[key]) && ( IsInstanceOf(variables[key][1],"rb") || IsInstanceOf(variables[key],"#this.componentName#"))){
						output[key] = arrayNew(1);
						for(var i = 1; i <= arrayLen(variables[key]); i++){
							output[key][i] = variables[key][i]._export();
						}
					}else{
						output[key] = variables[key];
					}
				}
			}
		}
		return output;
	}

	public function _import(data){
		for(key in data){
			variables[key] = data[key];
		}
	}

	public function _inject(name, func){
		this[name] = func;
	}

	public function _get(key){
		if(structKeyExists(variables,"#key#")){
			return variables[key];
		}else{
			return;
		}
	}

	public function _set(key, value){
		variables[key] = value;
		return this;
	}

	private function _own(componentName,referenceKey="",referenceColumn=""){
		if(len(trim(referenceKey))){
			if(len(trim(referenceColumn))){
				var referenceKeyID = variables[arguments.referenceColumn];
			}else{
				var referenceKeyID = variables[arguments.componentName & arguments.referenceKey];
			}
		}else{
			referenceKey = this.componentName & this.primaryKey;
			var referenceKeyID = variables[this.primaryKey];
		}
		if(len(trim(referenceKeyID))){
			variables[componentName] = this.rb.findAll(componentName,referenceKey &  " = ?",[referenceKeyID]);
		}else{
			variables[componentName] = arrayNew(1);
		}
		return variables[componentName];
	}

	private function isFunction(str) {
		if(ListFindNoCase(StructKeyList(GetFunctionList()),str)){
			return 1;
		}
		if(IsDefined(str) AND Evaluate("IsCustomFunction(#str#)")){
			return 1;
		}
		return 0;
	}
}