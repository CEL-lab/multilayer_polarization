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
