CREATE MIGRATION m1x7evrp4v4ervukqqmdu4rjwiakf45iw2q7nazyumw77ceb24g6wq
    ONTO m1i6q7vybrrde2mfclrnfjrvvgsuxpkm4yptsr6suwqh2i6iii4zia
{
  CREATE TYPE default::TypesDump {
      CREATE PROPERTY date: std::datetime;
      CREATE PROPERTY dateDuration: cal::date_duration;
      CREATE PROPERTY duration: std::duration;
      CREATE PROPERTY json: std::json;
      CREATE PROPERTY localDate: cal::local_date;
      CREATE PROPERTY localDateTime: cal::local_datetime;
      CREATE PROPERTY localTime: cal::local_time;
      CREATE PROPERTY relativeDuration: cal::relative_duration;
  };
  ALTER TYPE default::Person {
      CREATE LINK typesDump: default::TypesDump;
  };
};
