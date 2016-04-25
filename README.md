#Rapid Documention
From: https://github.com/Prefinem/RapidCF

##Intro

This is a ColdFusion ORM that was originally based on RedBeanPHP.  It assumes several standards (such as primary key's exist in tables) that are generally adhered to.

Base requirements for running RapidCF
* Microsoft SQL Server >= 2008 or MySQL >= 5 (Currently under testing.  Use at your own risk)
* ColdFusion >= 9.0.1 or Lucee >= 4

##Version
v.1.1

##Licensce

Licensed under MIT License
http://opensource.org/licenses/MIT

##Basic Usage
Here is some basic usage

###Setup

	var rapid = new rapid();
	rapid.setup("datsource_name");

####With CFPM

	var rapid = application.require('rapid');
	rapid.setup("datasource_name");

###Create and Save

	var user = rapid.dispense('user');
	user.FirstName = 'William';
	rapid.store(user);


###Load by ID and Save

	var user = rapid.load('user','cb323b67-e2a8-4bfd-99d4-848f9b9fddc6');
	user.FirstName = 'Billiam';
	rapid.store(user);


###Load by ID and Delete

	var user = rapid.load('user','cb323b67-e2a8-4bfd-99d4-848f9b9fddc6');
	rapid.trash(user);


###Find by type

	var user = rapid.findOne('user','firstName = ?',['Billiam']);


###Find All by type

	var users = rapid.find('user','firstName = ?',['Billiam']);


##Rapid Methods

###setup
Accepts: Datasource String Name, File path for Models (defaults to current directory)
Returns: void
Examples:

	var rapid = new rapid();
	rapid.setup("datsource_name","C:/websites/wwwroot/");

###dispense
Accepts: Component Name
Returns: Empty Bean
Example:

	var user = rapid.dispense('user');

###load
Accepts: Component Name, primaryKeyID
Returns: Bean
Example:

	var user = rapid.load('user',1);

###find
Accepts: Component Name, where clause using params (?), values (array)
Returns: First Bean
Example:

	var user = rapid.findOne('user','firstName = ?',['William']);

###findAll
Accepts: Component Name, where clause using params (?), values (array)
Returns: Array of Beans
Example:

	var users = rapid.find('user','firstName = ?',['William']);

###store
Accepts: Bean
Returns: void
Example:

	rapid.store(user);

###storeAll
Accepts: Array of Beans
Returns: void
Example:

	rapid.storeAll(users);

###trash
Accepts: Bean
Returns: void
Example:

	rapid.trash(user);

###query
Accepts: Component Name, Query String, Array of Params
Returns: Single Bean (first record) of query
Example:

	user = rapid.query("user","SELECT id,name FROM user ORDER BY name");
	user = rapid.query("user","SELECT id,name FROM user WHERE name = ?",["Billiam"]);

###queryAll
Accepts: Bean, Query String, Array of Params
Returns: All Beans of query
Example:

	users = rapid.queryAll("user","SELECT id,name FROM user");
	users = rapid.queryAll("user","SELECT id,name FROM user WHERE name = ?",["Billiam"]);

###exportAll
Accepts: Array of Beans
Returns: Array of Structs
Example:

	usersStruct = rapid.exportAll(users);

###importAll
Accepts: Component Name, Array of Data Structures
Returns: Array of Beans
Example:

	var importArray = NewArray(1);
	importArray[1] = {"firstName":"Billiam","lastName":"Bopper"};
	importArray[2] = {"firstName":"Ryno","lastName":"Ralley"};
	var users = rapid.importAll("user",importArray);

###own
Accepts: Bean, owned Component Name, bean Column, owned Component Column, owned Beans
Returns: Array of Beans
Example:

	var addresses = rapid.own(user, 'address', 'id', 'userid');

-----

##Beans
Beans are RapidCF Objects created by rapid.  They are what Rapid uses for all CRUD operations

###Models
To add a model for a Bean, you will need to ensure that a <componentName>Model.cfc file exists in your file path for Models.  While Models are stored in Beans, They have access to the bean data through "this.bean".

	component displayname="userModel" {

		function getFullName(){
			return this.bean.firstName & " " & this.bean.lastName;
		}
	}

###Data Attributes
Each Bean stores it's data in the public this scope.

	var user = rapid.dispense("user");
	user.FirstName = "Billiam";
	user.LastName = "Bopper";
	var firstName = user.FirstName;
	if(isDefined("user.firstName")){
		//First Name exists in user
	}else{
		//First Name doesn't exist in user
	}

###Bean Methods
A RapidCF Bean has a few built in methods to help with Lazy Loading and data manipulation

####export
Accepts: Array of keys to export (not required)
Returns: Struct
Description: Exports the object, and all children objects

####import
Accepts: Array of keys to import (not required)
Description: Imports a struct into the object

####ownComponentName
Description: Loads all children objects of componentName based on primaryKey and primaryKeyID or loads all parent or horizontal relationship components when passed bean column name and own component column name
Example:

	//Get Children
	var messages = user.ownMessages();

	//Get Parent
	//This assumes that the current object/record has the parent name + ID ('UserID') in it's records.
	//It then matches that value to the parent ('user') to the passed referenceKey ('ID')
	var user = message.ownUser('ID');
	//This can be used for parent records, or many to many records

####null
Description: This will null a field and ensure that said value is nulled in the database
Example:

	user.null('FirstName');

##TODO

###Prefetch
Prefetch data using one SQL Query versus having the n+1 issue we have now.

###research DBinfo
See how dbinfo() gets it's data and if it caches it