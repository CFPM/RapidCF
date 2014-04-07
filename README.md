#ORMService Documention
From: https://github.com/Prefinem/RedBeanCF

##Intro

This is a ORM solution that is based on RedBeanPHP.  It assumes several standards (such as primary key's exist in tables) that are generally adhered to.

Base requirements for running RedBeanCF
* Microsoft SQL Datasource
* ColdFusion 9.0.1

##Version
v.0.1

##Licensce

Licensed under MIT License
http://opensource.org/licenses/MIT

##Basic Usage
There is a patch of the Interactive Interview that includes the usage of the ORMService for all CRUD operations.  If you would like the patch to test, you can contact William

###Setup
	var ORM = new ORMService();
	ORM.setup("datsource_name");

###Create and Save
	var RAQObject = ORM.dispense('RegistrationAttendeeQueue');

	RAQObject.setFirstName('William');

	var RAQObjectID = ORM.store(RAQObject);


###Load by ID and Save
	var RAQObject = ORM.load('RegistrationAttendeeQueue','cb323b67-e2a8-4bfd-99d4-848f9b9fddc6');

	RAQObject.setFirstName('Billiam');

	var RAQObjectID = ORM.store(RAQObject);


###Load by ID and Delete
	var RAQObject = ORM.load('RegistrationAttendeeQueue','cb323b67-e2a8-4bfd-99d4-848f9b9fddc6');

	ORM.trash(RAQObject);


###Find by type
	var RAQObject = ORM.find('RegistrationAttendeeQueue','firstName = ?',['Billiam']);

returns a single object (first one it finds) or false


###Find All by type
	var RAQObjects = ORM.findAll('RegistrationAttendeeQueue','firstName = ?',['Billiam']);

return an array of objects.  If no results found, array is empty



##ORMService Methods

###setup
Accepts: Datasource String Name
Returns: void
Examples:

	var ORM = new ORMService();
	ORM.setup("datsource_name");

###dispense
Accepts: Component Name
Returns: Empty Component Object
Example:

	var user = ORM.dispense('User');

###load
Accepts: Component Name, primaryKeyID
Returns: Component Object
Example:

	var user = ORM.load('User',1);

###find
Accepts: Component Name, where clause using params (?), values (array)
Returns: First Component Object
Example:

	var user = ORM.find('User','firstName = ?',[]);

###findAll
Accepts: Component Name, where clause using params (?), values (array)
Returns: Array of Component Objects
Example:

	var users = ORM.findAll('User','firstName = ?',[]);

###store
Accepts: Component Object
Returns: Primary Key ID of Stored Item
Example:

	var userID = ORM.store(user);

###storeAll
Accepts: Array of Component Objects
Returns: void
Example:

	ORM.storeAll(users);

###trash
Accepts: Component Object
Returns: void
Example:

	ORM.trash(user);

###query
Accepts: Component Object, Query String, Array of Params
Returns: single object (first record) of query
Example:

	user = ORM.query("user","SELECT id,name FROM user ORDER BY name");
	user = ORM.query("user","SELECT id,name FROM user WHERE name = ?",["Billiam"]);

###queryAll
Accepts: Component Object, Query String, Array of Params
Returns: all objects of query
Example:

	users = ORM.queryAll("user","SELECT id,name FROM user");
	users = ORM.queryAll("user","SELECT id,name FROM user WHERE name = ?",["Billiam"]);

###exportAll
Accepts: Array of Component Objects
Returns: Array of Structs
Example:

	usersStruct = ORM.exportAll(users);

###importAll
Accepts: Component Name, Array of Data Structures
Returns: Array of Component Objects
Example:

	var importArray = NewArray(1);
	importArray[1] = {"firstName":"Billiam","lastName":"Bopper"};
	importArray[2] = {"firstName":"Ryno","lastName":"Ralley"};
	var users = ORM.importAll("user",importArray);

-----

##Component Objects
Component Objects are ORMEntity Objects created by ORM.  They are what ORMService uses for all CRUD operations

####Setters and Getters
Each Component Object has the ability to dynamically call getters and setters on itself.  This allows you to add variables to an object even if they are not a database column along.  When data is saved, only the columns of the table will be saved.

Getters also have the ability to be chained

	var user = ORM.dispense("user");
	user.setFirstName("Billiam").setLastName("Bopper");

###Component Object Methods
Along with the standard get/set methods, a ORMEntity Object has a few built in methods to help with Lazy Loading

####_export
Description: Exports the object, and all children objects

####_import
Description: Imports a struct into the object

###_inject
Description: Load a function into the Component Object to allow Component Level Functions
Example:

		public function lastFirstName (){
			return variables['lastName'] & ", " & variables['firstName'];
		}

		public function testFunc(){
			var user = ORM.load('user',1);
			user._inject("lastFirstName",lastFirstName);
			lastFirstName = user.lastFirstName();
		}

####_ownComponentName
Description: Loads all children objects of componentName based on primaryKey and primaryKeyID or loads all parent or horizontal relationship components when passed relationship key
Example:

	//Get Children
	var messages = user._ownMessages();

	//Get Parent
	//This assumes that the current object/record has the parent name + ID ('UserID') in it's records.
	//It then matches that value to the parent ('User') to the passed referenceKey ('ID')
	var user = message.ownUser('ID');
	//This can be used for parent records, or many to many records

##TODO

###Prefetch
Prefetch data using one SQL Query versus having the n+1 issue we have now.

###findAlll
Dispense once, and then copy the rest of the time

###research DBinfo
See how dbinfo() gets it's data and if it caches it
