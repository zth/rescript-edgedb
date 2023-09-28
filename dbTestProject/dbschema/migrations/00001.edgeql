CREATE MIGRATION m1glcdxeyvhdseptas3yrpq2bt44ob76hfqnenri7clygayy76n3sa
    ONTO initial
{
  CREATE TYPE default::Pet {
      CREATE REQUIRED PROPERTY name: std::str;
      CREATE PROPERTY paws: std::int32;
  };
  CREATE TYPE default::Person {
      CREATE MULTI LINK pets: default::Pet;
      CREATE PROPERTY age: std::int32;
      CREATE REQUIRED PROPERTY name: std::str;
  };
  CREATE SCALAR TYPE default::PublishStatus EXTENDING enum<Published, Unpublished>;
  CREATE TYPE default::Movie {
      CREATE MULTI LINK actors: default::Person;
      CREATE REQUIRED PROPERTY status: default::PublishStatus;
      CREATE REQUIRED PROPERTY title: std::str;
  };

  
};
