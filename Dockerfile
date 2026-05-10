FROM postgres:16

COPY ./db/Tienda-1.sql /docker-entrypoint-initdb.d/Tienda-1.sql