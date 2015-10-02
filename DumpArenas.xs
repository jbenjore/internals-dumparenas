/* This code uses several internal APIs. I'm declaring PERL_CORE
 * purely so this is visible to anyone grepping CPAN for code that
 * does this sort of thing.
 *
 *   Copied and pasted structure of S_visit from sv.c
 *   Used PL_sv_arenaroot
 *   Used do_sv_dump (instead of sv_dump)
 *   Used pv_display
 */
#define PERL_CORE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

void DumpPointer( pTHX_ PerlIO *f, SV *sv ) {
  if ( &PL_sv_undef == sv ) {
    PerlIO_puts(f, "sv_undef");
  }
  else if (&PL_sv_yes == sv) {
    PerlIO_puts(f, "sv_yes");
  }
  else if (&PL_sv_no == sv) {
    PerlIO_puts(f, "sv_no");
  }
  else if (&PL_sv_placeholder == sv) { /* deleted hash entry */
    PerlIO_printf(f, "sv_placeholder");
  }
  else {
    PerlIO_printf(f, "0x%"UVxf, PTR2UV(sv));
  }
}

void
DumpAvARRAY( pTHX_ PerlIO *f, SV *sv) {
  I32 key = 0;

  PerlIO_printf(f,"AvARRAY(0x%"UVxf") = {",PTR2UV(AvARRAY(sv)));
  if ( AvMAX(sv) != AvFILL(sv) ) {
    PerlIO_puts(f,"{");
  }
  
  for ( key = 0; key <= AvMAX(sv); ++key ) {
    DumpPointer(aTHX_ f, AvARRAY(sv)[key]);
    
    /* Join with something */
    if ( AvMAX(sv) == AvFILL(sv) ) {
      if (key != AvMAX(sv)) {
        PerlIO_puts(f, ",");
      }
    }
    else {
      PerlIO_puts(
        f,
        AvFILL(sv) == key ? "}{" :
        AvMAX(sv) == key  ? "}" :
        ","
      );
    }
  }
  PerlIO_puts(f,"}\n\n");
}

void
DumpHvARRAY( pTHX_ PerlIO *f, SV *sv) {
  I32 key = 0;
  HE *entry;
  SV *tmp = newSVpv("",0);

  PerlIO_printf(f,"HvARRAY(0x%"UVxf")\n",PTR2UV(HvARRAY(sv)));

  for ( key = 0; key <= HvMAX(sv); ++key ) {
    for ( entry = HvARRAY(sv)[key]; entry; entry = HeNEXT(entry) ) {
      if ( HEf_SVKEY == HeKLEN(entry) ) {
        PerlIO_printf(
          f, "  [SV 0x%"UVxf"] => ",
          PTR2UV(HeKEY(entry)));
      }
      else {
        PerlIO_printf(
          f, "  [0x%"UVxf" %s] => ",
          PTR2UV(HeKEY(entry)),
          pv_display(
            tmp,
            HeKEY(entry), HeKLEN(entry), HeKLEN(entry),
            0 ));
      }
      DumpPointer(aTHX_ f, HeVAL(entry));
      PerlIO_puts(f, "\n");
    }
  }
  PerlIO_puts(f,"\n");

  SvREFCNT_dec(tmp);
}

void
DumpHashKeys( aTHX_ PerlIO *f, SV *sv) {
  I32 key = 0;
  HE *entry;
  SV *tmp = newSVpv("",0);

  PerlIO_printf(f,"HASH KEYS at 0x%"UVxf"\n", PTR2UV(sv));
  
  for ( key = 0; key <= HvMAX(sv); ++key ) {
    for ( entry = HvARRAY(sv)[key]; entry; entry = HeNEXT(entry) ) {
      if ( HEf_SVKEY == HeKLEN(entry) ) {
        PerlIO_printf(f, "    SV 0x%"UVxf"\n", HeKEY(entry) );
      }
      else {
        PerlIO_printf(f, "    0x%"UVxf" %s\n", HeKEY(entry),
                      pv_display( (SV*)tmp, (const char*)HeKEY(entry),
                                  HeKLEN(entry), HeKLEN(entry), 0 ) );
      } 
    }
  }
  PerlIO_puts(f,"\n\n");

  SvREFCNT_dec(tmp);
}

void
DumpArenasPerlIO( pTHX_ PerlIO *f) {
  SV *arena;
  SV *verstash = NULL;

  /* Workaround core bug in the version module
   * https://rt.cpan.org/Ticket/Display.html?id=81635
   * %version:: has a broken SvSTASH */
#if PERL_VERSION >= 18
  verstash = get_hv("version::", 0);
#endif

  for (arena = PL_sv_arenaroot; arena; arena = (SV*)SvANY(arena)) {
    const SV *const arena_end = &arena[SvREFCNT(arena)];
    SV *sv;

    /* See also the static function S_visit in perl's sv.c
     * This is a copied and pasted implementation of that function.
     */
    PerlIO_printf(f,"START ARENA = (0x%"UVxf"-0x%"UVxf")\n\n",PTR2UV(arena),PTR2UV(arena_end));
    for (sv = arena + 1; sv < arena_end; ++sv) {
      if (SvTYPE(sv) != SVTYPEMASK && SvREFCNT(sv)) {

        /* Dump the plain SV */
        if (sv != verstash)
          do_sv_dump(0,f,sv,0,0,0,0);
        PerlIO_puts(f,"\n");
        
        /* Dump AvARRAY(0x...) = {{0x...,0x...}{0x...}} */
        switch (SvTYPE(sv)) {
        case SVt_PVAV:
          if ( AvARRAY(sv) && AvMAX(sv) != -1 ) {
            DumpAvARRAY( aTHX_ f,sv);
          }
          break;
        case SVt_PVHV:
          if ( HvARRAY(sv) && HvMAX(sv) != -1 ) {
            DumpHvARRAY( aTHX_ f,sv);
          }
          
          if ( ! HvSHAREKEYS(sv) ) {
            DumpHashKeys( aTHX_ f,sv);
          }
          
          break;
        }
      }
      else {
        PerlIO_printf(f,"AVAILABLE(0x%"UVxf")\n\n",PTR2UV(sv));
      }
    }
    PerlIO_printf(f,"END ARENA = (0x%"UVxf"-0x%"UVxf")\n\n",PTR2UV(arena),PTR2UV(arena_end));
  }
}

void
DumpArenas( pTHX ) {
  DumpArenasPerlIO( aTHX_ Perl_error_log );
}

void
DumpArenasFd( pTHX_ int fd ) {
  PerlIO *f = (PerlIO*)PerlIO_fdopen( fd, "w" );
  DumpArenasPerlIO( aTHX_ f );
}

MODULE = Internals::DumpArenas  PACKAGE = Internals::DumpArenas
  
PROTOTYPES: DISABLE

void
DumpArenas()
    CODE:
        DumpArenas( aTHX );

void
DumpArenasFd( int fd )
    CODE:
        DumpArenasFd( aTHX_ fd );
