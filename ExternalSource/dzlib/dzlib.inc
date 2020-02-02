{$INCLUDE 'dzlibjedi.inc'}

{$IFDEF DELPHI7_UP}
// TBitBtn.WordWrap was introduced in Delphi 7
{$DEFINE HAS_BITBTN_WORDWRAP}
// So was the $WARN USE_BEFORE_DEF define
{$DEFINE SUPPORTS_WARN_USE_BEFORE_DEF}
// Not sure about TBitmap.SetSize, was it introduced with Delphi 7 or later?
{$DEFINE SUPPPORTS_BITMAP_SETSIZE}
{$ENDIF}


{$IFDEF DELPHI2005_UP}
// Delphi 6 and 7 understood deprecated, but not for types
{$DEFINE SUPPORTS_DEPRECATED_TYPES}
{$ENDIF}

{$IFDEF DELPHIX_TOKYO_UP}
{$DEFINE FILECTRL_DIRECTORYEXISTS_IS_DEPRECATED}
{$ENDIF}

// The following cond. defines address errors in various Delphi versions regarding the declaration
// of the FHandle field of THandleStream and the corresponding Create constructor parameter:

{$IFDEF DELPHI2009_UP}
// THandleStream.FHandle is declared as THandle (before that it's an Integer)
{$DEFINE THANDLESTREAM_HANDLE_IS_THANDLE}
{$ENDIF}

{$IFDEF DELPHIXE2_UP}
// AHandle is declared as THandle (otherwise it's an Integer)
{$DEFINE THANDLESTREAM_CREATE_HANDLE_IS_THANDLE}
{$ENDIF}

{$WARN SYMBOL_PLATFORM OFF}
{$WARN UNIT_PLATFORM OFF}

