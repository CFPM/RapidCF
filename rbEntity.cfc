component {
	function init() {
		return this;
	}
	public function onMissingMethod(MissingMethodName, MissingMethodArguments){
		if(Find("set",arguments.MissingMethodName)){
			var key = Replace(arguments.MissingMethodName,"set","");
			return set(key,arguments.MissingMethodArguments[1]);
		}else if(Find("get",arguments.MissingMethodName)){
			var key = Replace(arguments.MissingMethodName,"get","");
			return get(key);
		}else if(Find("_own",arguments.MissingMethodName)){
			var component = Replace(arguments.MissingMethodName,"_own","");
			var referenceKey = len(trim(arguments.MissingMethodArguments[1])) ? arguments.MissingMethodArguments[1] : "";
			return _own(component,referenceKey);
		}else{
			throw (message="Missing Method", type="error");
		}
	}
	public function _export(){
		var output = {};
		for(key in variables){
			if(key != "THIS" && !isFunction(key)){
				if(IsInstanceOf(variables[key],"BaseEntity")){
					output[key] = variables[key]._export();
				}else if(isArray(variables[key]) && IsInstanceOf(variables[key][1],"BaseEntity")){
					output[key] = arrayNew(1);
					for(var i = 1; i <= arrayLen(variables[key]); i++){
						output[key][i] = variables[key][i]._export();
					}
				}else{
					output[key] = variables[key];
				}
			}
		}
		return output;
	}

	public function _import(data){
		for(key in data){
			variables[key] = data;
		}
	}

	public function _inject(name, func){
		this[name] = func;
	}

	private function get(key){
		if(structKeyExists(variables,"#key#")){
			return variables[key];
		}else{
			return "";
		}
	}

	private function set(key, value){
		variables[key] = value;
		return this;
	}

	private function _own(component,referenceKey=""){
		if(len(trim(referenceKey))){
			var referenceKeyID = variables[arguments.component & arguments.referenceKey];
		}else{
			referenceKey = this.componentName & this.primaryKey;
			var referenceKeyID = variables[this.primaryKey];
		}
		if(len(trim(referenceKeyID))){
			variables[component] = this.ORMService.findAll(component,referenceKey &  " = ?",[referenceKeyID]);
		}else{
			variables[component] = arrayNew(1);
		}
		return variables[component];
	}

	private function isFunction(str) {
		if(ListFindNoCase(StructKeyList(GetFunctionList()),str)) return 1;
		if(IsDefined(str) AND Evaluate("IsCustomFunction(#str#)")) return 1;
		return 0;
	}
}