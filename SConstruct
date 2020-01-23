# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------#
#   Copyright (C) 2016 by Christoph Thelen                                #
#   doc_bacardi@users.sourceforge.net                                     #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
#-------------------------------------------------------------------------#


#----------------------------------------------------------------------------
#
# Set up the Muhkuh Build System.
#
SConscript('mbs/SConscript')
Import('atEnv')

# Create a build environment for the Cortex-R7 and Cortex-A9 based netX chips.
env_cortexR7 = atEnv.DEFAULT.CreateEnvironment(['gcc-arm-none-eabi-4.9', 'asciidoc'])
env_cortexR7.CreateCompilerEnv('NETX4000', ['arch=armv7', 'thumb'], ['arch=armv7-r', 'thumb'])

# Create a build environment for the Cortex-M4 based netX chips.
env_cortexM4 = atEnv.DEFAULT.CreateEnvironment(['gcc-arm-none-eabi-4.9', 'asciidoc'])
env_cortexM4.CreateCompilerEnv('NETX90', ['arch=armv7', 'thumb'], ['arch=armv7e-m', 'thumb'])

# Build the platform libraries.
SConscript('platform/SConscript')


#----------------------------------------------------------------------------
#
# Get the source code version from the VCS.
#
atEnv.DEFAULT.Version('#targets/version/version.h', 'templates/version.h')
atEnv.DEFAULT.Version('#targets/hboot_snippet.xml', 'templates/hboot_snippet.xml')


#----------------------------------------------------------------------------
#
# Build all files.
#
sources = """
	src/header.c
	src/main.c
"""


# The list of include folders. Here it is used for all files.
astrIncludePaths = ['src', '#platform/src', '#platform/src/lib', '#targets/version']

global PROJECT_VERSION


#
# Build the netX90 snippet.
#
tEnv90 = atEnv.NETX90.Clone()
tEnv90.Append(CPPPATH = astrIncludePaths)
tEnv90.Replace(LDFILE = 'src/netx90/netx90_com_intram.ld')
tSrc90 = tEnv90.SetBuildPath('targets/netx90_com_intram', 'src', sources)
tElf90 = tEnv90.Elf('targets/netx90_com_intram/read_rotaryswitch_snippet_netx90_com_intram.elf', tSrc90 + tEnv90['PLATFORM_LIBRARY'])
tTxt90 = tEnv90.ObjDump('targets/netx90_com_intram/read_rotaryswitch_snippet_netx90_com_intram.txt', tElf90, OBJDUMP_FLAGS=['--disassemble', '--source', '--all-headers', '--wide'])
tBin90 = tEnv90.ObjCopy('targets/netx90_com_intram/read_rotaryswitch_snippet_netx90_com_intram.bin', tElf90)
tTmp90 = tEnv90.GccSymbolTemplate('targets/netx90_com_intram/snippet.xml', tElf90, GCCSYMBOLTEMPLATE_TEMPLATE='targets/hboot_snippet.xml', GCCSYMBOLTEMPLATE_BINFILE=tBin90[0])

# Create the snippet from the parameters.
aArtifactGroupReverse90 = ['com', 'hilscher', 'hw', 'util', 'netx90']
atSnippet90 = {
    'group': '.'.join(aArtifactGroupReverse90),
    'artifact': 'read_rotaryswitch',
    'version': PROJECT_VERSION,
    'vcs_id': tEnv90.Version_GetVcsIdLong(),
    'vcs_url': tEnv90.Version_GetVcsUrl(),
    'license': 'GPL-2.0',
    'author_name': 'Muhkuh team',
    'author_url': 'https://github.com/muhkuh-sys',
    'description': 'Read rotary switches make them available on netX90',
    'categories': ['netx90', 'booting'],
    'parameter': {
        'TARGET_ADDRESS': {'help': 'Address to write to the value from the rotaty switch.'},
        'MMIO_SELECT': {'help': 'MMIO selection used for rotary switch to be read in.'}
    }

}
strArtifactPath90 = 'targets/snippets/%s/%s/%s' % ('/'.join(aArtifactGroupReverse90), atSnippet90['artifact'], PROJECT_VERSION)
snippet_netx90_com = tEnv90.HBootSnippet('%s/%s-%s.xml' % (strArtifactPath90, atSnippet90['artifact'], PROJECT_VERSION), tTmp90, PARAMETER=atSnippet90)

# Create the POM file.
tPOM90 = tEnv90.POMTemplate('%s/%s-%s.pom' % (strArtifactPath90, atSnippet90['artifact'], PROJECT_VERSION), 'templates/pom.xml', POM_TEMPLATE_GROUP=atSnippet90['group'], POM_TEMPLATE_ARTIFACT=atSnippet90['artifact'], POM_TEMPLATE_VERSION=atSnippet90['version'], POM_TEMPLATE_PACKAGING='xml')


#
# Build the netX4000 snippet.
#
tEnv4000 = atEnv.NETX4000.Clone()
tEnv4000.Append(CPPPATH = astrIncludePaths)
tEnv4000.Replace(LDFILE = 'src/netx4000/netx4000.ld')
tSrc4000 = tEnv4000.SetBuildPath('targets/netx4000', 'src', sources)
tElf4000 = tEnv4000.Elf('targets/netx4000/read_rotaryswitch_snippet_netx4000.elf', tSrc4000 + tEnv4000['PLATFORM_LIBRARY'])
tTxt4000 = tEnv4000.ObjDump('targets/netx4000/read_rotaryswitch_snippet_netx4000.txt', tElf4000, OBJDUMP_FLAGS=['--disassemble', '--source', '--all-headers', '--wide'])
tBin4000 = tEnv4000.ObjCopy('targets/netx4000/read_rotaryswitch_snippet_netx4000.bin', tElf4000)
tTmp4000 = tEnv4000.GccSymbolTemplate('targets/netx4000/snippet.xml', tElf4000, GCCSYMBOLTEMPLATE_TEMPLATE='targets/hboot_snippet.xml', GCCSYMBOLTEMPLATE_BINFILE=tBin4000[0])

# Create the snippet from the parameters.
aArtifactGroupReverse4000 = ['com', 'hilscher', 'hw', 'util', 'netx4000']
atSnippet4000 = {
    'group': '.'.join(aArtifactGroupReverse4000),
    'artifact': 'read_rotaryswitch',
    'version': PROJECT_VERSION,
    'vcs_id': tEnv4000.Version_GetVcsIdLong(),
    'vcs_url': tEnv4000.Version_GetVcsUrl(),
    'license': 'GPL-2.0',
    'author_name': 'Muhkuh team',
    'author_url': 'https://github.com/muhkuh-sys',
    'description': 'Read rotary switches make them available on netX4000.',
    'categories': ['netx4000', 'booting'],
    'parameter': {
        'TARGET_ADDRESS': {'help': 'Address to write to the value from the rotaty switch.'},
        'MMIO_SELECT': {'help': 'MMIO selection used for rotary switch to be read in.'}
    }

}
strArtifactPath4000 = 'targets/snippets/%s/%s/%s' % ('/'.join(aArtifactGroupReverse4000), atSnippet4000['artifact'], PROJECT_VERSION)
snippet_netx4000_com = tEnv4000.HBootSnippet('%s/%s-%s.xml' % (strArtifactPath4000, atSnippet4000['artifact'], PROJECT_VERSION), tTmp4000, PARAMETER=atSnippet4000)

# Create the POM file.
tPOM4000 = tEnv4000.POMTemplate('%s/%s-%s.pom' % (strArtifactPath4000, atSnippet4000['artifact'], PROJECT_VERSION), 'templates/pom.xml', POM_TEMPLATE_GROUP=atSnippet4000['group'], POM_TEMPLATE_ARTIFACT=atSnippet4000['artifact'], POM_TEMPLATE_VERSION=atSnippet4000['version'], POM_TEMPLATE_PACKAGING='xml')

# Create binaries for verification
hboot_netx4000_test02 = tEnv4000.HBootImage('targets/verification/test02/test_snippet_netx4000_rotary.bin', 'verification/test02/test_snippet_netx4000_rotary.xml')
