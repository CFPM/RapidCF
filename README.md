#RedBean Documention
From: https://github.com/Prefinem/RedBeanCF

##Intro

This is a ORM solution that is based on RedBeanPHP.  It assumes several standards (such as primary key's exist in tables) that are generally adhered to.

Base requirements for running RedBeanCF
* Microsoft SQL Datasource
* ColdFusion 9.0.1

##Version
v.0.2

##Licensce

Licensed under MIT License
http://opensource.org/licenses/MIT

##Basic Usage
There is a patch of the Interactive Interview that includes the usage of the RedBean for all CRUD operations.  If you would like the patch to test, you can contact William

###Setup
	var ORM = new RedBean();
	ORM.setup("datsource_name");

###Create and Save
	var user = ORM.dispense('user');

	user.FirstName = 'William';

	var userID = ORM.store(user);


###Load by ID and Save
	var user = ORM.load('user','cb323b67-e2a8-4bfd-99d4-848f9b9fddc6');

	user.FirstName = 'Billiam';

	var userID = ORM.store(user);


###Load by ID and Delete
	var user = ORM.load('user','cb323b67-e2a8-4bfd-99d4-848f9b9fddc6');

	ORM.trash(user);


###Find by type
	var user = ORM.find('user','firstName = ?',['Billiam']);

returns a single bean (first one it finds) or false


###Find All by type
	var users = ORM.findAll('user','firstName = ?',['Billiam']);

return an array of bean.  If no results found, array is empty



##RedBean Methods

###setup
Accepts: Datasource String Name, File path for Models (defaults to current directory)
Returns: void
Examples:

	var ORM = new RedBean();
	ORM.setup("datsource_name","C:/websites/wwwroot/");

###dispense
Accepts: Component Name
Returns: Empty Bean
Example:

	var user = ORM.dispense('User');

###load
Accepts: Component Name, primaryKeyID
Returns: Bean
Example:

	var user = ORM.load('User',1);

###find
Accepts: Component Name, where clause using params (?), values (array)
Returns: First Bean
Example:

	var user = ORM.find('User','firstName = ?',[]);

###findAll
Accepts: Component Name, where clause using params (?), values (array)
Returns: Array of Beans
Example:

	var users = ORM.findAll('User','firstName = ?',[]);

###store
Accepts: Bean
Returns: Primary Key ID of Stored Item
Example:

	var userID = ORM.store(user);

###storeAll
Accepts: Array of Beans
Returns: void
Example:

	ORM.storeAll(users);

###trash
Accepts: Bean
Returns: void
Example:

	ORM.trash(user);

###query
Accepts: Component Name, Query String, Array of Params
Returns: Single Bean (first record) of query
Example:

	user = ORM.query("user","SELECT id,name FROM user ORDER BY name");
	user = ORM.query("user","SELECT id,name FROM user WHERE name = ?",["Billiam"]);

###queryAll
Accepts: Bean, Query String, Array of Params
Returns: All Beans of query
Example:

	users = ORM.queryAll("user","SELECT id,name FROM user");
	users = ORM.queryAll("user","SELECT id,name FROM user WHERE name = ?",["Billiam"]);

###exportAll
Accepts: Array of Beans
Returns: Array of Structs
Example:

	usersStruct = ORM.exportAll(users);

###importAll
Accepts: Component Name, Array of Data Structures
Returns: Array of Beans
Example:

	var importArray = NewArray(1);
	importArray[1] = {"firstName":"Billiam","lastName":"Bopper"};
	importArray[2] = {"firstName":"Ryno","lastName":"Ralley"};
	var users = ORM.importAll("user",importArray);

-----

##Beans
Beans are RedBeanCF Objects created by ORM.  They are what RedBean uses for all CRUD operations

###Models
To add a model for a Bean, you will need to ensure that a <componentName>Model.cfc file exists in your file path for Models and that it extends RedBeanCF/model.cfc.  While Models are stored in Beans, They have access to the bean data through "this.bean".

	component displayname="userModel" extends="RedBeanCF.model" {
		
		function getFullName(){
			return this.bean.firstName & " " & this.bean.lastName;
		}
	}

###Data Attributes
Each Bean stores it's data in the public this scope.

	var user = ORM.dispense("user");
	user.FirstName = "Billiam";
	user.LastName = "Bopper";
	var firstName = user.FirstName;
	if(isDefined("user.firstName")){
		//First Name exists in user
	}else{
		//First Name doesn't exist in user
	}

###Bean Methods
A RedBeanCF Bean has a few built in methods to help with Lazy Loading and data manipulation

####export
Accepts: Array of keys to export (not required)
Returns: Struct
Description: Exports the object, and all children objects

####import
Description: Imports a struct into the object

####ownComponentName
Description: Loads all children objects of componentName based on primaryKey and primaryKeyID or loads all parent or horizontal relationship components when passed bean column name and own component column name
Example:

	//Get Children
	var messages = user.ownMessages();

	//Get Parent
	//This assumes that the current object/record has the parent name + ID ('UserID') in it's records.
	//It then matches that value to the parent ('User') to the passed referenceKey ('ID')
	var user = message.ownUser('ID');
	//This can be used for parent records, or many to many records

##TODO

###Prefetch
Prefetch data using one SQL Query versus having the n+1 issue we have now.

###findAll
Dispense once, and then copy the rest of the time

###research DBinfo
See how dbinfo() gets it's data and if it caches it

###Export/Import
Allows a list of export/import items

###Find
Find,FindOne,FindAll