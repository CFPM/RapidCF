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
		if(Find("import", arguments.MissingMethodName)){
			//We have to do this because import is a reserved word for ColdFusion
			this._import(arguments.MissingMethodArguments[1]);
		}else if(Find("own",arguments.MissingMethodName)){
			var component = Replace(arguments.MissingMethodName,"own","");
			var referenceKey = len(trim(arguments.MissingMethodArguments[1])) ? arguments.MissingMethodArguments[1] : "";
			var referenceColumn = len(trim(arguments.MissingMethodArguments[2])) ? arguments.MissingMethodArguments[2] : "";
			return own(component,referenceKey,referenceColumn);
		}else{
			var params = "";
			for(param in MissingMethodArguments){
				listAppend(params,"'#param#'");
			}
			return Evaluate("this._info.model.#MissingMethodName#(#params#)");
		}
	}

	public function loadModel(modelName){
		this._info.model = new "#modelName#"(this);
	}

	public function export(keys=arrayNew(1)){
		var output = {};
		if(arrayLen(keys)>0){
			for(key in keys){
				output[key] = this[key];
			}
		}else{
			for(key in this){
				if(key != "THIS" && key != "KEY" && !isFunction(key)){
					if(IsInstanceOf(this[key],"bean") || IsInstanceOf(this[key],"#this._info.componentName#")){
						output[key] = this[key]._export();
					}else if(isArray(this[key]) && ( IsInstanceOf(this[key][1],"bean") || IsInstanceOf(this[key],"#this._info.componentName#"))){
						output[key] = arrayNew(1);
						for(var i = 1; i <= arrayLen(this[key]); i++){
							output[key][i] = this[key][i]._export();
						}
					}else{
						output[key] = this[key];
					}
				}
			}
		}
		return output;
	}

	public function _import(data){
		for(key in data){
			this[key] = data[key];
		}
	}

	private function own(componentName,referenceKey="",referenceColumn=""){
		if(len(trim(referenceKey))){
			if(len(trim(referenceColumn))){
				var referenceKeyID = this[arguments.referenceColumn];
			}else{
				var referenceKeyID = this[arguments.componentName & arguments.referenceKey];
			}
		}else{
			referenceKey = this._info.componentName & this._info.primaryKey;
			var referenceKeyID = this[this._info.primaryKey];
		}
		if(len(trim(referenceKeyID))){
			this[arguments.componentName] = this.rb.findAll(arguments.componentName,referenceKey &  " = ?",[referenceKeyID]);
		}else{
			this[arguments.componentName] = arrayNew(1);
		}
		return this[arguments.componentName];
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