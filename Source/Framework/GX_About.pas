unit GX_About;

interface

uses
  Classes, Controls, Forms, StdCtrls, ExtCtrls, GX_BaseForm;

type
  TfmAbout = class(TfmBaseForm)
    lblGExperts: TLabel;
    btnClose: TButton;
    lblVersion: TLabel;
    pnlLogo: TPanel;
    imgLogo: TImage;
    btnEmail: TButton;
    lblWebPage: TLabel;
    lblProjectLeader: TLabel;
    lblContributors: TLabel;
    lblErik: TLabel;
    lblWebSite: TLabel;
    lblPreRelease1: TLabel;
    lblPreRelease2: TLabel;
    mmoBuildDetails: TMemo;
    mmoContributors: TMemo;
    procedure btnEmailClick(Sender: TObject);
    procedure lblWebPageClick(Sender: TObject);
  private
    procedure InitVersionInfoControls;
  public
    constructor Create(AOwner: TComponent); override;
    // If you release an experimental GExperts, either
    // set gblAboutFormClass to your own descentant of this form or
    // call SetCustomBuildDetails and SetCustomBuildEmails to
    // describe your build and provide feedback email adresses.
    class procedure SetCustomBuildDetails(const Details: string);
    class procedure SetCustomBuildEmails(const _BugEmail, _SuggestionEmail: string);
  end;

type
  TAboutFormClass = class of TfmAbout;

var
  gblAboutFormClass: TAboutFormClass;

implementation

{$R *.dfm}
{$R GX_About.res}

uses
  SysUtils, Graphics,
  GX_GenericUtils, GX_FeedbackWizard;

const
  BUG_EMAIL = 'bugs@gexperts.org';  // Do not localize.
  SUGGESTION_EMAIL = 'suggestions@gexperts.org'; // Do not localize.
var
  BuildDetails: string = '';
  BugEmail: string = BUG_EMAIL;
  SuggestionEmail: string = SUGGESTION_EMAIL;

procedure TfmAbout.btnEmailClick(Sender: TObject);
begin
  TfmFeedbackWizard.Execute(self, BugEmail, SuggestionEmail);
  Close;
end;

procedure TfmAbout.lblWebPageClick(Sender: TObject);
var
  lbl: TLabel;
  url: string;
begin
  lbl := Sender as TLabel;
  url := lbl.Hint;
  if url = '' then
    url := lbl.Caption;
  GXShellExecute(url, '', True);
end;

constructor TfmAbout.Create(AOwner: TComponent);
begin
  inherited;
  SetFontBold(lblContributors);
  SetFontBold(lblProjectLeader);
  SetFontBold(lblWebSite);
  SetFontBold(lblVersion);
  SetFontBold(lblGExperts);
  SetFontColor(lblPreRelease1, clRed);
  SetFontColor(lblPreRelease2, clRed);
  SetFontSize(lblGExperts, +4);
  SetFontSize(lblVersion, +4);
  SetFontUnderline(lblErik);
  SetFontUnderline(lblWebPage);
  SetFontColor(lblErik, clBlue);
  SetFontColor(lblWebPage, clBlue);
  SetFontColor(mmoBuildDetails, clRed);

  imgLogo.Picture.Bitmap.LoadFromResourceName(HInstance, 'ABOUT_WIZ');
  InitVersionInfoControls;

  if NotEmpty(BuildDetails) then
  begin
    if (BugEmail = BUG_EMAIL) or (SuggestionEmail = SUGGESTION_EMAIL) then
      btnEmail.Visible := False;
    mmoBuildDetails.Visible := True;
    mmoBuildDetails.Lines.Text := BuildDetails;
  end
  else
  begin
    if gblAboutFormClass = TfmAbout then
      btnEmail.Visible := True;
    mmoBuildDetails.Visible := False;
  end;
end;

procedure TfmAbout.InitVersionInfoControls;
resourcestring
  SVersion = 'Version';
  SUnknown = '<unknown>';
var
  Version: TVersionNumber;
begin
  try
    Version := GetFileVersionNumber(ThisDllName);
    lblVersion.Caption := Format('%s %d.%d%d', [SVersion, Version.Major, Version.Minor, Version.Release]);
  except
    lblVersion.Caption := Format('%s %s', [SVersion, SUnknown]);
  end;
  if Version.Build <> 0 then
    lblVersion.Caption := lblVersion.Caption + '.' + IntToStr(Version.Build);
end;

class procedure TfmAbout.SetCustomBuildDetails(const Details: string);
begin
  BuildDetails := Details;
end;

class procedure TfmAbout.SetCustomBuildEmails(const _BugEmail, _SuggestionEmail: string);
begin
  BugEmail := _BugEmail;
  SuggestionEmail := _SuggestionEmail;
end;

initialization
  gblAboutFormClass := TfmAbout;
end.

