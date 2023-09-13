--- githubList githubdan alınan liste sen ve repler beraber var
--- githubTweets githubtan alınan listedeki herkesin olduğu liste
--- allPPAList yunus hocadan gelen liste
--- allPPATweets yunus hocadan gelen listedeki tüm idlerin tüm tweetleri
--- githubListSenator githubListteki senatör olanların listesi

--- hashtagleri sayıyor
CREATE FUNCTION count_hashtags(table_name TEXT) RETURNS TABLE(hashtag TEXT, frequency INT)
AS
$$
  SELECT hashtag, COUNT(*) AS frequency
  FROM (
      SELECT json_extract(value, '$.tag') AS hashtag
      FROM main.allPPATweets,
        json_each(entities, '$.hashtags')
      WHERE json_valid(entities) = 1
        AND table_name = ?
    )
  GROUP BY hashtag
  ORDER BY frequency DESC;
$$;

--- githubListten senatör olanları seçiyoruz
select *
from githubList
where type = "sen";

--- github listesindeki senatörlerden allPPA listesinde olanlar.
--- yani bu döenmde seçime giren senatörler. bazıları yeni olabilir
--- bunu githubPPAKesisim tablosuna yazdırdım
SELECT *
FROM githubListSenator s
  INNER JOIN allPPAList a ON a.GOVTWIT_ID = s.twitter_id;

--- githubPPAKesisim talbosundaki kisilerin tüm hesaplarına ait twitler sayıldı kontrol için
SELECT count(*) FROM
(select *
from allPPATweets a
         inner join githubPPAKesisim g on
        (a.author_id = g.BIOID)
        or (a.author_id = g.GOVTWIT_ID)
        or (a.author_id = g.OTWIT_ID)
        or (a.author_id = g.OTWIT_ID_2)
        or (a.author_id = g.OTWIT_ID_3)
        or (a.author_id = g.OTWIT_ID_4)
        or (a.author_id = g.OTWIT_ID_5)
        or (a.author_id = g.OTWIT_ID_6));

---
SELECT COUNT(*)
      from allPPATweets
               inner join githubPPAKesisim on (allPPATweets.author_id = githubPPAKesisim.GOVTWIT_ID);
---
select COUNT(*)
from githubTweets
         inner join githubPPAKesisim on githubTweets.author_id = githubPPAKesisim.GOVTWIT_ID;
--- üstteki iki sorgunun sonuçları aynı geliyor. daha sonradan ikilik olmaması için aşağıdaki
--- bir sorguda bir satır eksik

--- githubPPAKesisim talbosundaki kisilerin tüm hesaplarına ait twitler allPPATweetsFiltered tablosuna yazıldı
CREATE TABLE allPPATweetsFiltered AS
select *
from allPPATweets a
         inner join githubPPAKesisim g on
        (a.author_id = g.BIOID)
        or (a.author_id = g.OTWIT_ID)
        or (a.author_id = g.OTWIT_ID_2)
        or (a.author_id = g.OTWIT_ID_3)
        or (a.author_id = g.OTWIT_ID_4)
        or (a.author_id = g.OTWIT_ID_5)
        or (a.author_id = g.OTWIT_ID_6);

--- githubdan gelen verideki senatörlerin tweetleri filtrelendi
--- yanlarına yunus hocadan gelen bilgiler eklendi
--- githubTweetsFiltered tablosunu yazıldı
CREATE TABLE githubTweetsFiltered AS
select *
from githubTweets g
         inner join githubListSenator l on g.author_id = l.twitter_id
         left join allPPAList a on g.author_id = a.GOVTWIT_ID;

--- bir takım sayımlar
select count(*) from githubTweetsFiltered;
select count(*) from githubTweets;
select count(distinct twitter_id) from githubTweetsFiltered;

--- burada githubtan gelen senatör twitleri ve allPPAdaki diğer hesaplardan atılan twitlerin toplamı bulunuyor
CREATE TABLE finalTweetsTable AS
SELECT *
FROM allPPATweetsFiltered
UNION ALL
SELECT *
FROM githubTweetsFiltered;

--- biri 94 biri 124 40 id yan hesaplardan geliyor
select count(distinct twitter_id) from githubListSenator;
select count(distinct author_id) from finalTweetsTable;
select count(*) from finalTweetsTable;

--- allPPATweetsFiltered tablosunda tweet_id boş olanlar
select * from allPPATweetsFiltered where twitter_id = NULL;

--- finalTable oluşturuldu
SELECT twitter_id, author_id, hashtag,
  COUNT(*) AS frequency
FROM (
    SELECT json_extract(value, '$.tag') AS hashtag,
      main.finalTweetsTable.author_id AS author_id,
      main.finalTweetsTable.twitter_id AS twitter_id
    FROM main.finalTweetsTable,
      json_each(entities, '$.hashtags')
    WHERE json_valid(entities) = 1
  )
GROUP BY author_id, hashtag
ORDER BY frequency DESC;

---
select count(distinct twitter_id) from finalTable;
select count(distinct author_id) from finalTable;
select count(distinct hashtag) from finalTable;

---
select hashtag, count(hashtag) from finalTable group by hashtag;

---
SELECT * FROM count_hashtags('main.allPPATweets');

--- uniqueleri say
SELECT hashtag,
  COUNT(*) AS frequency,
  COUNT(DISTINCT author_id) AS unique_users
FROM (
    SELECT json_extract(value, '$.tag') AS hashtag,
           author_id
    FROM main.finalTweetsTable,
      json_each(entities, '$.hashtags')
    WHERE json_valid(entities) = 1
  )
GROUP BY hashtag
ORDER BY frequency DESC;

--- hashtagleri dosyaya yazdır
select distinct hashtag from finalTable

---
SELECT *
FROM finalTable
WHERE hashtag LIKE '%LoveisLove%'
   OR hashtag LIKE '%LGBTQHistoryMonth%'
   OR hashtag LIKE '%RespectForMarriageAct%'
   OR hashtag LIKE '%RespectforMarriage%'
   OR hashtag LIKE '%EqualityAct%'
   OR hashtag LIKE '%MarriageEquality%'
   OR hashtag LIKE '%ComingOutDay%'
   OR hashtag LIKE '%Pride%'
   OR hashtag LIKE '%NationalComingOutDay%';

---
SELECT *
FROM finalTable
WHERE hashtag LIKE '%RespectforMarriage%';

--- region diye bir column oluşturuyorum
ALTER TABLE githubListSenator ADD COLUMN region TEXT;

--- Then, update the new 'region' column with 'south' if the 'state' column has one of the specified abbreviations
UPDATE githubListSenator SET region = (
  CASE
    WHEN state IN ('AL', 'AR', 'DE', 'FL', 'GA', 'KY', 'LA', 'MD', 'MS', 'NC', 'OK', 'SC', 'TN', 'TX', 'VA', 'WV') THEN 'south'
    ELSE 'north'
  END
);

--- sütunları ekle
ALTER TABLE finalTable ADD COLUMN full_name TEXT;
ALTER TABLE finalTable ADD COLUMN state TEXT;
ALTER TABLE finalTable ADD COLUMN region TEXT;
ALTER TABLE finalTable ADD COLUMN party TEXT;

--- sütunları doldur
UPDATE finalTable
SET
  full_name = (SELECT githubListSenator.full_name FROM githubListSenator WHERE finalTable.twitter_id = githubListSenator.twitter_id),
  state = (SELECT githubListSenator.state FROM githubListSenator WHERE finalTable.twitter_id = githubListSenator.twitter_id),
  region = (SELECT githubListSenator.region FROM githubListSenator WHERE finalTable.twitter_id = githubListSenator.twitter_id),
  party = (SELECT githubListSenator.party FROM githubListSenator WHERE finalTable.twitter_id = githubListSenator.twitter_id);

---
select distinct OFFICE1, OFFICE1_LEVEL from allPPAList;
select distinct BIOID from allPPAList where OFFICE1_LEVEL = 1;

---- senatörliste id ekliyorum OFFICE2
UPDATE senatorlist SET OFFICE2 = ROWID;
select count(OFFICE2) from senatorlist;

---------------- yeni listedeki tüm twitler listesi

CREATE TABLE allPPATweetsFiltered AS
select *
from allPPATweets a
    inner join senatorlist g on
    (a.author_id = g.BIOID)
    or (a.author_id = g.OTWIT_ID)
    or (a.author_id = g.OTWIT_ID_2)
    or (a.author_id = g.OTWIT_ID_3)
    or (a.author_id = g.OTWIT_ID_4)
    or (a.author_id = g.OTWIT_ID_5)
    or (a.author_id = g.OTWIT_ID_6)
    or (a.author_id = g.GOVTWIT_ID)
    or (a.author_id = g.PTWIT_ID)
    or (a.author_id = g.twitter_id);

CREATE TABLE githubTweetsFiltered AS
select *
from githubTweets a
    inner join senatorlist g on
    (a.author_id = g.BIOID)
    or (a.author_id = g.OTWIT_ID)
    or (a.author_id = g.OTWIT_ID_2)
    or (a.author_id = g.OTWIT_ID_3)
    or (a.author_id = g.OTWIT_ID_4)
    or (a.author_id = g.OTWIT_ID_5)
    or (a.author_id = g.OTWIT_ID_6)
    or (a.author_id = g.GOVTWIT_ID)
    or (a.author_id = g.PTWIT_ID)
    or (a.author_id = g.twitter_id);

----
CREATE TABLE tumTweets AS
SELECT * FROM allPPATweetsFiltered
UNION ALL
SELECT * FROM githubTweetsFiltered;

----

SELECT count(*) FROM tumTweets WHERE tumTweets.OFFICE2 IS NULL;

---- kaç kişinin twiti yok ve bunlar kimler
select count(distinct OFFICE2) from tumTweets;

SELECT p.*
FROM senatorlist p
LEFT JOIN tumTweets t ON p.OFFICE2 = t.OFFICE2
WHERE t.id IS NULL;

---
--- unique hashtagleri say
SELECT hashtag,
  COUNT(*) AS frequency,
  COUNT(DISTINCT OFFICE2) AS unique_users
FROM (
    SELECT json_extract(value, '$.tag') AS hashtag,
           OFFICE2
    FROM main.tumTweets2,
      json_each(entities, '$.hashtags')
    WHERE json_valid(entities) = 1
  )
GROUP BY hashtag
-- HAVING unique_users > 1
ORDER BY frequency DESC;

--- örnek twitlerle beraber hashtag tablosunu veriyor.
WITH HashtagMetrics AS (
    SELECT
        json_extract(value, '$.tag') AS hashtag,
        COUNT(*) AS frequency,
        COUNT(DISTINCT OFFICE2) AS unique_users
    FROM main.tumTweets2,
        json_each(entities, '$.hashtags')
    WHERE json_valid(entities) = 1
    GROUP BY hashtag
    HAVING unique_users > 1
),
HashtagLikes AS (
    -- Get hashtags, their corresponding likes, and tweet text
    SELECT
        json_extract(value, '$.tag') AS hashtag,
        json_extract(public_metrics, '$.like_count') AS like_count,
        text AS tweet_text
    FROM main.tumTweets2,
        json_each(entities, '$.hashtags')
    WHERE json_valid(entities) = 1
),
RankedTweets AS (
    -- Rank tweets for each hashtag based on their like counts
    SELECT
        h.hashtag,
        h.like_count,
        h.tweet_text,
        ROW_NUMBER() OVER(PARTITION BY h.hashtag ORDER BY h.like_count DESC) as rnk
    FROM HashtagLikes h
)
-- Combine metrics with top 3 tweets
SELECT
    hm.hashtag,
    hm.frequency,
    hm.unique_users,
    rt.like_count,
    rt.tweet_text
FROM HashtagMetrics hm
JOIN RankedTweets rt ON hm.hashtag = rt.hashtag
WHERE rt.rnk <= 3
ORDER BY hm.frequency DESC, rt.like_count DESC;


--- chech duplicates and create new tumTweets table
SELECT *
FROM tumTweets2
WHERE id IN (
    SELECT id
    FROM tumTweets2
    GROUP BY id
    HAVING COUNT(id) > 1
)
ORDER BY id;

CREATE TABLE tumTweets2 AS
SELECT *
FROM tumTweets
WHERE rowid IN (
    SELECT MIN(rowid)
    FROM tumTweets
    GROUP BY id
);


---- mention2 columnunun clusterlar ile oluşturulması

CREATE TABLE tumTweets3 AS SELECT * FROM tumTweets2;


ALTER TABLE tumTweets3 ADD COLUMN entities2 TEXT;

UPDATE tumTweets3 SET entities2 = entities;


UPDATE tumTweets3
SET entities2 = REPLACE(entities2,
                          '"tag": "' || (SELECT hashtag FROM all_hashtags) || '"',
                          '"tag": "' || (SELECT cluster FROM all_hashtags) || '"')
WHERE entities2 LIKE '%"tag": "%' || (SELECT hashtag FROM all_hashtags) || '%"';

--- unique hashtagleri say
SELECT hashtag,
  COUNT(*) AS frequency,
  COUNT(DISTINCT OFFICE2) AS unique_users
FROM (
    SELECT json_extract(value, '$.tag') AS hashtag,
           OFFICE2
    FROM main.tumTweets3,
      json_each(entities2, '$.hashtags')
    WHERE json_valid(entities2) = 1
  )
GROUP BY hashtag
HAVING unique_users > 1
ORDER BY frequency DESC;

--- create id-hashtag table
CREATE TABLE tweet_hashtags (
    author_id TEXT,
    hashtag TEXT
);

ALTER TABLE tweet_hashtags ADD COLUMN cluster;

UPDATE tweet_hashtags
SET cluster = (
    SELECT all_hashtags.cluster
    FROM all_hashtags
    WHERE all_hashtags.hashtag = tweet_hashtags.hashtag
);

--- hashtag summary oluşturuldu
CREATE TABLE hashtag_summary (
    cluster TEXT,
    frequency INTEGER,
    unique_users INTEGER
);

INSERT INTO hashtag_summary (cluster, frequency, unique_users)
SELECT
    cluster,
    COUNT(*) AS frequency,
    COUNT(DISTINCT author_id) AS unique_users
FROM tweet_hashtags
GROUP BY cluster
HAVING unique_users > 1;

--- create id-hashtag table 2
CREATE TABLE tweet_hashtags2 (
    OFFICE2 TEXT,
    hashtag TEXT
);

--- here some code is in python

ALTER TABLE tweet_hashtags2 ADD COLUMN cluster;

UPDATE tweet_hashtags2
SET cluster = (
    SELECT all_hashtags.cluster
    FROM all_hashtags
    WHERE all_hashtags.hashtag = tweet_hashtags2.hashtag
);


--- party sadeleştirme
select OFFICE2, "PARTY NAME, ENGLISH", party, finalParty from senatorlist;

ALTER TABLE senatorlist ADD finalParty TEXT;

UPDATE senatorlist SET finalParty = COALESCE(party, "PARTY NAME, ENGLISH");

--- region sadeleştirme

ALTER TABLE senatorlist ADD finalRegion TEXT;

select OFFICE2, "OFFICE1_CONSTITUENCYLEVEL2", state_abb, state, finalRegion from senatorlist;

UPDATE senatorlist SET finalRegion = COALESCE(state, state_abb);

--- sex sadeleştirme

ALTER TABLE senatorlist ADD finalSex TEXT;

select OFFICE2, FullName, gender2, GENDER, finalSex from senatorlist;

--- aday mı değil mi sadeleştirme

ALTER TABLE senatorlist ADD finalCandidate TEXT;

select OFFICE2, kazanan, full_name, FullName, finalElection, finalCandidate from senatorlist;

UPDATE senatorlist
SET finalCandidate = CASE
    WHEN finalElection = 'w' THEN 'can'
    WHEN finalElection = 'l' THEN 'can'
    WHEN finalElection IS 'nan' THEN 'notcan'
    ELSE finalCandidate -- keep the current value if none of the conditions match
END;


--- region diye bir column oluşturuyorum
ALTER TABLE senatorlist ADD COLUMN region TEXT;

--- Then, update the new 'region' column with 'south' if the 'state' column has one of the specified abbreviations
UPDATE senatorlist SET region = (
  CASE
    WHEN state IN ('AL', 'AR', 'DE', 'FL', 'GA', 'KY', 'LA', 'MD', 'MS', 'NC', 'OK', 'SC', 'TN', 'TX', 'VA', 'WV') THEN 'south'
    ELSE 'north'
  END
);
