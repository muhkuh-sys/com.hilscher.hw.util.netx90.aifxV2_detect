/***************************************************************************
 *   Copyright (C) 2013 by Christoph Thelen                                *
 *   doc_bacardi@users.sourceforge.net                                     *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/


#ifndef __HEADER_H__
#define __HEADER_H__

// unlock register
const unsigned long volatile *asic_ctrl_access_key = 0xff4012c0;
// pull down enable (enable pulldown with bit 4)
const unsigned char uc_pull_down_enable =  4;
const unsigned long *pul_pad_ctrl_com_io1 = 0xff40101c;
const unsigned long *pul_pad_ctrl_com_io2 = 0xff401020;
const unsigned long *pul_pad_ctrl_mii0_txd1 = 0xff401054;

typedef struct VERSION_HEADER_STRUCT
{
	unsigned long ulVersionMajor;
	unsigned long ulVersionMinor;
	unsigned long ulVersionMicro;
	const char    acVersionVcs[16];
} VERSION_HEADER_T;
// mask bits have to be 1, not checked for (assumed in reset state)
const unsigned long *pul_clock_enable0_mask =  0xff40126c;
// wm: set register and accordingly it's write mask to change the value
const unsigned char bit_xc_misc = 8;
const unsigned char bit_clock_xMAC0 = 4;
const unsigned char bit_xc_misc_wm = 24;
const unsigned char bit_clock_xMAC0_wm = 20;
const unsigned long *pul_clock_enable0 = 0xff401268;

extern const VERSION_HEADER_T tVersionHeader __attribute__ ((section (".header")));

// pinns of register en_xmac_status_shared0 where to retrieve the status from
const unsigned long *pul_xmac_status_shared0 = 0xff111440;
typedef enum EN_XMAC_STATUS_SHARED_0{
  pin_gpio0_in,
  pin_gpio1_in,
  pin_gpio2_in_phy_led0,
  pin_gpio3_in_phy_led1,
  pin_gpio4_in_phy_led2, // COM_IO1 (speed)
  pin_gpio5_in_phy_led3, // COM_IO0 (duplex)
}en_xmac_status_shared0;

#endif  /* __HEADER_H__ */
