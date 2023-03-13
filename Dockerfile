FROM tarantool/tarantool:2.3.1
COPY src/* /opt/tarantool
EXPOSE 52080 
CMD ["tarantool", "/opt/tarantool/app.lua"]