include Makefile

qjs_host$(EXE): $(OBJDIR)/profile_qjs_host.o $(QJS_LIB_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)
