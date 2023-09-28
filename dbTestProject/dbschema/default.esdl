module default {
  scalar type PublishStatus extending enum<Published, Unpublished>;

  type Pet {
    required property name -> str;
    property nickname -> str;
    property paws -> int32;
  }

  type Person {
    required property name -> str;
    property age -> int32;
    multi link pets -> Pet;
  }

  type Movie {
    required property title -> str;
    required property status -> PublishStatus;
    multi link actors -> Person;
  }
};