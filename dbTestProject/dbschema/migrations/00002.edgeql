CREATE MIGRATION m1i6q7vybrrde2mfclrnfjrvvgsuxpkm4yptsr6suwqh2i6iii4zia
    ONTO m1glcdxeyvhdseptas3yrpq2bt44ob76hfqnenri7clygayy76n3sa
{
  ALTER TYPE default::Pet {
      CREATE PROPERTY nickname: std::str;
  };

  INSERT Person {
    name := 'John Doe',
    age := 30,
    pets := {
        (INSERT Pet {
        name := 'Rex',
        paws := 4
        }),
        (INSERT Pet {
        name := 'Fluffy',
        paws := 4
        })
    }
    };

    INSERT Person {
    name := 'Jane Smith',
    age := 28,
    pets := {
        (INSERT Pet {
        name := 'Bella',
        paws := 4
        })
    }
    };

    INSERT Person {
    name := 'Bob Johnson',
    age := 35,
    pets := {
        (INSERT Pet {
        name := 'Max',
        paws := 4
        })
    }
    };

    INSERT Movie {
    title := 'The Great Adventure',
    status := <PublishStatus>'Published',
    actors := {
        (SELECT Person FILTER .name = 'John Doe')
    }
    };

    INSERT Movie {
    title := 'The Mystery',
    status := <PublishStatus>'Published',
    actors := {
        (SELECT Person FILTER .name = 'Jane Smith')
    }
    };

    INSERT Movie {
    title := 'The Thriller',
    status := <PublishStatus>'Published',
    actors := {
        (SELECT Person)
    }
    };
};
