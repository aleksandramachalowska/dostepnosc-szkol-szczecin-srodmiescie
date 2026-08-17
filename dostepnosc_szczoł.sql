Github
-- ==========================================
-- Analiza czasu dojścia pieszego do szkół w Śródmieściu Szczecina
-- PostgreSQL + PostGIS
-- ==========================================

-- Transformacja układów warstw OSM do EPSG:2176

CREATE TABLE planet_osm_roads_2176 AS
SELECT
   *,
    ST_Transform(way, 2176) AS geom_2176
FROM planet_osm_roads;

ALTER TABLE planet_osm_roads_2176
DROP COLUMN way;

ALTER TABLE planet_osm_roads_2176
RENAME COLUMN geom_2176 TO geom;

CREATE TABLE planet_osm_point_2176 AS
SELECT *
FROM planet_osm_point;

ALTER TABLE planet_osm_point_2176
ALTER COLUMN way
TYPE geometry(Point, 2176)
USING ST_Transform(way, 2176);

-- Utworzenie warstwy zawierającej szkoły dzielnicy Śródmieście

CREATE TABLE szkoly_pkt AS
SELECT *
FROM planet_osm_point_2176
WHERE amenity='school';

CREATE TABLE szkoly_srodmiescie AS SELECT *
FROM szkoly_pkt s
JOIN srodmiescie d
ON ST_Intersects(s.way,d.geom);

--Stworzenie warstwy zawierającej preferowane typy dróg z odpowiednim buforem wokół dzielnicy

CREATE TABLE bufor_srodmiescie AS 
SELECT ST_Buffer(geom,500) AS geom
FROM srodmiescie;

CREATE TABLE drogi_srodmiescie AS SELECT
r.osm_id,
r.highway,
r.oneway,
ST_Intersection(r.geom,b.geom) AS geom
FROM planet_osm_roads_2176 r
JOIN bufor_srodmiescie b
ON ST_Intersects(r.geom,b.geom)
WHERE r.highway IN(
'primary',
'primary_link',
'secondary',
'secondary_link',
'tertiary',
'residential',
'unclassified',
'service',
'footway',
'path',
'cycleway'
);

-- Sprawdzenie wartości null kolumny highway

SELECT COUNT(*)
FROM planet_osm_roads_2176 r
JOIN bufor_srodmiescie b
ON ST_Intersects(r.geom,b.geom)
WHERE 
r.highway IS NULL
AND r.boundary IS NULL
AND r.railway IS NULL;

SELECT 
boundary,
railway,
COUNT(*) AS liczba
FROM planet_osm_roads_2176 r
JOIN bufor_srodmiescie b
ON ST_Intersects(r.geom,b.geom)
WHERE 
r.highway IS NULL
GROUP BY boundary, railway 
ORDER BY liczba DESC;

-- Sprawdzenie sieci dróg w warstwie planet_osm_line

SELECT 
highway,
COUNT(*) AS liczba
FROM planet_osm_line_2176 r
JOIN bufor_srodmiescie b
ON ST_Intersects(r.geom,b.geom)
GROUP BY highway
ORDER BY liczba DESC;

CREATE TABLE drogi_srodmiescie_piesze AS 
SELECT *
FROM planet_osm_line_2176 
WHERE 
highway IS NOT NULL
 AND highway NOT IN ('platform', 'corridor','elevator', 'construction','proposed','track','cycleway');

CREATE TABLE drogi_piesze AS SELECT *
FROM drogi_srodmiescie_piesze r
JOIN bufor_srodmiescie b
ON ST_Intersects(r.way,b.geom);

-- Usunięcie z typu service wszystkich rekordów poza allay i null

DELETE FROM drogi_piesze
WHERE highway = 'service'
  AND service IN (
      'driveway',
      'parking_aisle',
      'emergency_access',
      'drive-through'
  );

-- Połączenie obu warstw linowych zawierających drogi

CREATE TABLE siec_srodmiescie AS
SELECT
    osm_id,
    highway,
    oneway,
    geom
FROM drogi_piesze
UNION ALL
SELECT
    r.osm_id,
    r.highway,
    r.oneway,
    r.geom
FROM drogi_srodmiescie r
WHERE NOT EXISTS (
    SELECT 1
    FROM drogi_piesze p
    WHERE p.osm_id = r.osm_id
);

-- Sprawdzenie czy odcinki przecinają się oraz ilości odcinków bez połączeń

SELECT
    COUNT(*) AS liczba_polaczen
FROM siec_srodmiescie a
JOIN siec_srodmiescie b
    ON a.osm_id <> b.osm_id
    AND ST_Intersects(a.geom, b.geom);

SELECT COUNT(*) AS odcinki_bez_polaczenia
FROM siec_srodmiescie a
WHERE NOT EXISTS (
    SELECT 1
    FROM siec_srodmiescie b
    WHERE a.osm_id <> b.osm_id
      AND ST_Intersects(a.geom, b.geom)
);

-- Utworzenie węzłów w miejscach przecięcia sieci

CREATE TABLE siec_graf_geom AS
SELECT
    (ST_Dump(
        ST_Node(
            ST_Collect(geom)
        )
    )).geom AS geom
FROM siec_srodmiescie;

CREATE TABLE graf_srodmiescie AS
SELECT
    row_number() OVER () AS id,
    o.osm_id,
    o.highway,
    o.oneway,
    ST_Length(g.geom) AS length,
    g.geom
FROM siec_graf_geom g
CROSS JOIN LATERAL (
    SELECT
        o.osm_id,
        o.highway,
        o.oneway
    FROM siec_srodmiescie o
    WHERE ST_Intersects(g.geom, o.geom)
    ORDER BY ST_Length(ST_Intersection(g.geom, o.geom)) DESC
    LIMIT 1
) o;

CREATE TABLE konce_krawedzi AS
SELECT
    id,
    ST_StartPoint(geom) AS start_geom,
    ST_EndPoint(geom) AS end_geom
FROM graf_srodmiescie;

CREATE TABLE punkty_grafu AS
SELECT start_geom AS geom
FROM konce_krawedzi

UNION ALL

SELECT end_geom AS geom
FROM konce_krawedzi;

CREATE TABLE wezly_srodmiescie AS
SELECT
    row_number() OVER () AS node_id,
    geom
FROM punkty_grafu
GROUP BY geom;

-- Znalezienie dla każdej krawędzi węzła, który jest jej początkiem (source) i który jest końcem (target)

CREATE TABLE graf_srodmiescie_final AS
SELECT
    k.id,
    w_start.node_id AS source,
    w_end.node_id AS target,
    g.highway,
    g.oneway,
    g.length,
    g.geom
FROM graf_srodmiescie g
JOIN konce_krawedzi k
    ON g.id = k.id
JOIN wezly_srodmiescie w_start
    ON k.start_geom = w_start.geom
JOIN wezly_srodmiescie w_end
    ON k.end_geom = w_end.geom;

-- Utworzenie dwukierunkowego grafu

CREATE TABLE graf_srodmiescie_2kier AS
SELECT
    id,
    source,
    target,
    highway,
    oneway,
    length,
    geom
FROM graf_srodmiescie_final
UNION ALL
SELECT
    id,
    target AS source,
    source AS target,
    highway,
    oneway,
    length,
    geom
FROM graf_srodmiescie_final;

-- Utworzenie grafu z czasem pokonania drogi w zależności od jej typu

CREATE TABLE graf_czas AS
SELECT
    *,
    CASE
        WHEN highway = 'steps'
            THEN length / (2.5 / 3.6)
        WHEN highway = 'path'
            THEN length / (4.5 / 3.6)
        ELSE
            length / (5.0 / 3.6)
    END AS cost
FROM graf_srodmiescie_2kier;

-- Znalezienie najbliższego węzła dla każdej szkoły

CREATE TABLE szkoly_wezly AS
SELECT
    s.osm_id AS school_id,
    n.node_id,
    ST_Distance(s.way, n.geom) AS distance
FROM szkoly_srodmiescie s
CROSS JOIN LATERAL (
    SELECT
        node_id,
        geom
    FROM wezly_srodmiescie
    ORDER BY s.way <-> geom
    LIMIT 1
) n
WHERE s.amenity = 'school';

-- Znalezienie wszystkich węzłów do których mozna dojść kolejno w 5,10 i 15 minut od każdej szkoły

CREATE TABLE punkty_0_5_wszystkie_szkoly AS
SELECT
    s.school_id,
    d.node AS node_id,
    d.agg_cost,
    n.geom
FROM szkoly_wezly s
CROSS JOIN LATERAL (
    SELECT *
    FROM pgr_drivingDistance(
        'SELECT id, source, target, cost FROM graf_czas',
        s.node_id,
        300
    )
) d
JOIN wezly_srodmiescie n
    ON d.node = n.node_id;

CREATE TABLE punkty_5_10_wszystkie_szkoly AS
SELECT
    s.school_id,
    d.node AS node_id,
    d.agg_cost,
    n.geom
FROM szkoly_wezly s
CROSS JOIN LATERAL (
    SELECT *
    FROM pgr_drivingDistance(
        'SELECT id, source, target, cost FROM graf_czas',
        s.node_id,
        600
    )
) d
JOIN wezly_srodmiescie n
    ON d.node = n.node_id;

CREATE TABLE punkty_10_15_wszystkie_szkoly AS
SELECT
    s.school_id,
    d.node AS node_id,
    d.agg_cost,
    n.geom
FROM szkoly_wezly s
CROSS JOIN LATERAL (
    SELECT *
    FROM pgr_drivingDistance(
        'SELECT id, source, target, cost FROM graf_czas',
        s.node_id,
        900
    )
) d
JOIN wezly_srodmiescie n
    ON d.node = n.node_id;

-- Utworzenie izochron czasu dojścia

CREATE TABLE izochrony_do_5_szkoly AS
SELECT
    school_id,
    ST_ConcaveHull(
        ST_Collect(geom),
        0.5
    ) AS geom
FROM punkty_0_5_wszystkie_szkoly
GROUP BY school_id;

CREATE TABLE izochrony_5_10_szkoly AS
SELECT
    school_id,
    ST_ConcaveHull(
        ST_Collect(geom),
        0.5
    ) AS geom
FROM punkty_5_10_wszystkie_szkoly
GROUP BY school_id;

CREATE TABLE izochrony_10_15_szkoly AS
SELECT
    school_id,
    ST_ConcaveHull(
        ST_Collect(geom),
        0.5
    ) AS geom
FROM punkty_10_15_wszystkie_szkoly
GROUP BY school_id;


