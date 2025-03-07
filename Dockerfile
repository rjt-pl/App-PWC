FROM perl:latest
WORKDIR /srv/App::PWC
COPY . .
RUN cpanm --installdeps --notest --with-feature=accelerate .
EXPOSE 4000
CMD plackup -p 4000 bin/app.psgi
