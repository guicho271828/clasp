#include <clasp/gctools/telemetry.h>
#include <clasp/core/foundation.h>
#include <clasp/core/str.h>
#include <clasp/core/pathname.h>
#include <clasp/core/wrappers.h>


namespace telemetry {


Telemetry global_telemetry_search;

#define ARGS_core_telemetry_open "(pathname)"
#define DECL_core_telemetry_open ""
#define DOCS_core_telemetry_open ""
void core_telemetry_open(core::T_sp pathname) {
  core::Str_sp filename = core::cl_namestring(pathname);
  global_telemetry_search.open_read(filename->c_str());
}
#define MAX_WORDS 16


    std::string Telemetry::entry_as_string(Handle label, size_t num_read, Word data[])
    {
        std::string slabel = global_telemetry_search._Labels[label];
        char buffer[1024];
        switch (num_read) {
        case 0:
            sprintf(buffer,slabel.c_str());
            break;
        case 1:
            sprintf(buffer,slabel.c_str(), data[0] );
            break;
        case 2:
            sprintf(buffer,slabel.c_str(), data[0],data[1] );
            break;
        case 3:
            sprintf(buffer,slabel.c_str(), data[0],data[1],data[2] );
            break;
        case 4:
            sprintf(buffer,slabel.c_str(), data[0],data[1],data[2],data[3] );
            break;
        default:
            sprintf(buffer,"Add support for %d arguments", num_read);
        }
        return std::string(buffer);
    }

#define CANONICAL_POINTER(p) (p&(~0x7))

#define ARGS_core_telemetry_search "(addresses)"
#define DECL_core_telemetry_search ""
#define DOCS_core_telemetry_search ""
void core_telemetry_search(core::List_sp addresses) {
  global_telemetry_search.seek(0);
  size_t prev, cur;
  Telemetry::Header header;
  std::vector<std::string> results;
  std::vector<Telemetry::Word> tests;
  for ( auto it : addresses ) {
    core::T_sp address = oCar(it);
    if ( !address.fixnump() ) {
      SIMPLE_ERROR(BF("Inputs must all be fixnums"));
    }
    tests.push_back(address.unsafe_fixnum() & (~0x7));
  }
  Telemetry::Handle label;
  Telemetry::Word data[MAX_WORDS];
  while (1) {
      bool read = global_telemetry_search.read_header(header);
      if ( !read ) break;
      if ( global_telemetry_search.process_header(header) ) continue;
      size_t num_read = global_telemetry_search.read_data(label,MAX_WORDS,data);
      for ( int i(0); i<num_read; ++i ) {
          for ( auto it : tests ) {
              if ( it == CANONICAL_POINTER(data[i]) ) {
                  std::string entry = global_telemetry_search.entry_as_string(label,num_read,data);
                  results.push_back(entry);
              }
          }
      }
  }
  for ( auto& it: results ) {
    printf("%s:%d  %s\n", __FILE__, __LINE__, it.c_str());
  }
}


#define ARGS_core_telemetry_follow "(address)"
#define DECL_core_telemetry_follow ""
#define DOCS_core_telemetry_follow ""
    void core_telemetry_follow(core::T_sp address) {
        global_telemetry_search.seek(0);
        size_t prev, cur;
        Telemetry::Header header;
        std::vector<std::string> results;
        std::vector<Telemetry::Word> tests;
        if ( !address.fixnump() ) {
            SIMPLE_ERROR(BF("Input must be fixnum"));
        }   
        tests.push_back(address.unsafe_fixnum() & (~0x7));
        Telemetry::Handle label;
        Telemetry::Word data[MAX_WORDS];
        while (1) {
        TOP:
            bool read = global_telemetry_search.read_header(header);
            if ( !read ) break;
            if ( global_telemetry_search.process_header(header) ) continue;
            size_t num_read = global_telemetry_search.read_data(label,MAX_WORDS,data);
            for ( auto it : tests ) {
                if ( label == label_obj_fwd ) {
                    if ( it == CANONICAL_POINTER(data[0]) ) {
                        tests.push_back(data[1]);
                        goto TOP;
                    }
                }
                for ( int i(0); i<num_read; ++i ) {
                    if ( it == CANONICAL_POINTER(data[i]) ) {
                        std::string entry = global_telemetry_search.entry_as_string(label,num_read,data);
                        results.push_back(entry);
                    }
                }
            }
        }
        for ( auto& it: results ) {
            printf("%s:%d  %s\n", __FILE__, __LINE__, it.c_str());
        }
    }

#define ARGS_core_telemetry_dump "(&optional (begin 0) end)"
#define DECL_core_telemetry_dump ""
#define DOCS_core_telemetry_dump ""
void core_telemetry_dump(core::T_sp begin, core::T_sp end) {
  if ( !begin.fixnump() ) {
    SIMPLE_ERROR(BF("begin must be a FIXNUM"));
  }
  core::Fixnum fn_begin = begin.unsafe_fixnum();
  core::Fixnum fn_end;
  if ( end.nilp() ) {
    fn_end = gctools::most_positive_uint;
  } else if ( end.fixnump() ){
    fn_end = end.unsafe_fixnum();
  } else {
    SIMPLE_ERROR(BF("Illegal value for end"));
  }
  global_telemetry_search.seek(0);
  size_t cur;
  Telemetry::Header header;
  size_t idx = 0;
  Telemetry::Handle label;
  Telemetry::Word data[MAX_WORDS];
  while (1) {
      cur = ftell(global_telemetry_search._File);
      bool read = global_telemetry_search.read_header(header);
      ++idx;
      if ( !read ) break;
      if ( global_telemetry_search.process_header(header) ) continue;
      size_t num_read = global_telemetry_search.read_data(label,MAX_WORDS,data);
      if ( idx < fn_begin ) continue;
      if ( idx > fn_end ) break;
      std::string entry = global_telemetry_search.entry_as_string(label,num_read,data);
      printf("[%d]@%08x: %s\n", idx,cur, entry.c_str() );
  }
}

#define ARGS_core_telemetry_count "()"
#define DECL_core_telemetry_count ""
#define DOCS_core_telemetry_count ""
  size_t core_telemetry_count() {
  global_telemetry_search.seek(0);
  size_t prev, cur;
  Telemetry::Header header;
  size_t idx = 0;
  Telemetry::Handle label;
  Telemetry::Word data[MAX_WORDS];
  while (1) {
    bool read = global_telemetry_search.read_header(header);
    ++idx;
    if ( !read ) break;
    if ( global_telemetry_search.process_header(header) ) continue;
    size_t num_read = global_telemetry_search.read_data(label,MAX_WORDS,data);
  }
  return idx;
}




char* global_clasp_telemetry_file;
Telemetry global_telemetry;
Telemetry::Handle label_allocation;
Telemetry::Handle label_obj_pad;
Telemetry::Handle label_obj_scan_start;
Telemetry::Handle label_obj_scan;
Telemetry::Handle label_obj_isfwd_true;
Telemetry::Handle label_obj_isfwd_false;
Telemetry::Handle label_obj_skip;
Telemetry::Handle label_obj_fwd;
Telemetry::Handle label_obj_finalize;
Telemetry::Handle label_root_scan_start;
Telemetry::Handle label_root_scan_stop;
Telemetry::Handle label_smart_ptr_fix;
Telemetry::Handle label_tagged_pointer_fix;

void initialize_telemetry() {
  label_allocation = global_telemetry.intern("mps_allocation client@%p size: %lu kind: %lu");
  label_obj_pad = global_telemetry.intern("obj_pad base@%p size: %lu");
  label_obj_scan_start = global_telemetry.intern("obj_scan client@%p size: %lu");
  label_obj_scan = global_telemetry.intern("obj_scan client@%p header@%p kind: %lu");
  label_obj_isfwd_true = global_telemetry.intern("obj_isfwd == TRUE client@%p base@%p forward@%p");
  label_obj_isfwd_false = global_telemetry.intern("obj_isfwd == FALSE client@%p base@%p");
  label_obj_pad = global_telemetry.intern("obj_pad base@%p size: %lu");
  label_obj_fwd = global_telemetry.intern("obj_fwd old-client@%p new-client@%p");
  label_obj_skip = global_telemetry.intern("obj_skip in-client@%p  out-client@%p size=%lu");
  label_obj_finalize = global_telemetry.intern("obj_finalize addr@%p");
  label_root_scan_start = global_telemetry.intern("root_scan_start");
  label_root_scan_stop = global_telemetry.intern("root_scan_stop");
  label_smart_ptr_fix = global_telemetry.intern("smart_ptr_fix before@%p after@%p");
  label_tagged_pointer_fix = global_telemetry.intern("tagged_pointer_fix before@%p after@%p");
};

void initialize_telemetry_defuns() {
 CoreDefun(telemetry_open);
 CoreDefun(telemetry_search);
 CoreDefun(telemetry_dump);
 CoreDefun(telemetry_count);
 CoreDefun(telemetry_follow);
}

};
