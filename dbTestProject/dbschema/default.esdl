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
    link typesDump -> TypesDump;
  }

  type TypesDump {
    property date -> datetime;
    property localDateTime -> cal::local_datetime;
    property localDate -> cal::local_date;
    property relativeDuration -> cal::relative_duration;
    property duration -> duration;
    property dateDuration -> cal::date_duration;
    property localTime -> cal::local_time;
    property json -> json;
    
  }

  type Movie {
    required property title -> str;
    required property status -> PublishStatus;
    multi link actors -> Person;
  }
};