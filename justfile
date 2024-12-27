CWD := `pwd`
GDAL_FILE := "gdal-" + GDAL_VERSION + ".tar.gz"
GDAL_PREFIX := CWD + "/local/gdal-" + GDAL_VERSION
GDAL_VERSION := "3.8.4"
GEOS_CONFIG := CWD + "/local/gdal-" + GDAL_VERSION + "/bin/geos-config"
GEOS_FILE := "geos-" + GEOS_VERSION + ".tar.bz2"
GEOS_VERSION := "3.12.1"
PROJ_FILE := "proj-" + PROJ_VERSION + ".tar.gz"
PROJ_VERSION := "9.4.0"
SQLITE_FILE := "sqlite-autoconf-" + SQLITE_VERSION + ".tar.gz"
SQLITE_VERSION := "3450300"
SQLITE_YEAR := "2024"
PATH := env_var('PATH')

default:
    @echo 'Hello, world!'

# ---------------------------------------- gdal ----------------------------------------

[group('gdal')]
gdal-clean:
    rm -rvf build/
alias clean := gdal-clean
alias c := gdal-clean

[group('gdal')]
build:
    -mkdir local
    -mkdir build
    wget https://github.com/OSGeo/gdal/releases/download/v{{ GDAL_VERSION }}/{{ GDAL_FILE }}
    wget http://download.osgeo.org/geos/{{ GEOS_FILE }}
    wget https://download.osgeo.org/proj/{{ PROJ_FILE }}
    wget https://www.sqlite.org/{{ SQLITE_YEAR }}/{{ SQLITE_FILE }}
    tar -C build -xvf {{ GDAL_FILE }}
    tar -C build -xvf {{ GEOS_FILE }}
    tar -C build -xvf {{ PROJ_FILE }}
    tar -C build -xvf {{ SQLITE_FILE }}
    cd build/sqlite-autoconf-{{ SQLITE_VERSION }} && ./configure --prefix={{ GDAL_PREFIX }}
    cd build/sqlite-autoconf-{{ SQLITE_VERSION }} && make -j4
    cd build/sqlite-autoconf-{{ SQLITE_VERSION }} && make install
    expbuild \
        SQLITE3_LIBS="-L{{ GDAL_PREFIX }}/lib -lsqlite3" \
        SQLITE3_CFLAGS="-I${{ CWD }}/local/gdal-{{ GDAL_VERSION }}/include" \
        PATH="{{ CWD }}/local/gdal-{{ GDAL_VERSION }}/bin:{{ PATH }}"
    cd build/proj-{{ PROJ_VERSION }} && mkdir build
    cd build/proj-{{ PROJ_VERSION }}/build && cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX={{ GDAL_PREFIX }} .. && make -j4 && make install
    cd build/geos-{{ GEOS_VERSION }} && mkdir build
    cd build/geos-{{ GEOS_VERSION }}/build && cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX={{ GDAL_PREFIX }} .. && make -j4 && make install
    cd build/gdal-{{ GDAL_VERSION }} && mkdir build
    cd build/gdal-{{ GDAL_VERSION }}/build && mkdir build && cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX={{ GDAL_PREFIX }} -DSQLite3_INCLUDE_DIR={{ GDAL_PREFIX }}/include \
        -DSQLite3_LIBRARY={{ GDAL_PREFIX }}/lib/libsqlite3.dylib -DACCEPT_MISSING_SQLITE3_MUTEX_ALLOC=ON \
        -DACCEPT_MISSING_SQLITE3_RTREE=ON -DGDAL_USE_LIBKML=OFF -DGDAL_IGNORE_FAILED_CONDITIONS=ON \
        -DGDAL_USE_POPPLER=OFF ..
    cd build/gdal-{{ GDAL_VERSION }}/build && cmake --build . --target install
alias b := build
