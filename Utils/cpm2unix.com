�VConverts a textfile from CP/M to UNIX format.
(c) J. Elliott, 8 December 1993.
� �0�g-�� � <o& 6 �L:] �C�3:m �C�6!\ z �� �\ � <�'z� <9!z�-\ !�# �� � \ � <�L!\ ͓;�|� �Y��y�c�n�6�N�6��\ �� �� <Y�6c�|�L!z͓�6��|� �0�   �l� ��� <�*͈��X������X�>����lz� �� �:��̝o& <2~�� z� ��=��! 6���!z͓U�|�� ���:����������
��_� �O:o& �q<2����� �� ��,2�~#x���>!��=�-�=�-��-� ��-��/�!� ~#���F�O~#�H�l�E�h�O2��!f~#��  _ͅ�o����	Ë����� ���������͝Î~�ª�� <�#�@_ͅ:ͅ��.ͅ~�_ͅ#���No filename specified. Type UNIX2CPM /H for help.
$Two filenames are needed.
$ - file does not exist.
$ - error on opening file.
$ - read error.
$CPM2UNIX v1.00 - Converts textfiles from CP/M to Unix format.

Syntax:
      CPM2UNIX infile outfile {/E}

  The textfile will be converted. If the /E option is present,
the textfile will also be displayed.
  - file exists; Delete (Y/N)?$
This file cannot be deleted.
$                                                                        - Directory is full.
$ - Disk is full.
$ - Disk write error.
$                                                                                                                                                                                                                                                                � 