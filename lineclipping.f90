module lineclip

use, intrinsic :: iso_c_binding, only: sp=>C_FLOAT, dp=>C_DOUBLE, i64=>C_LONG_LONG, sizeof=>c_sizeof, c_int
use, intrinsic :: iso_fortran_env, only : stdout=>output_unit, stderr=>error_unit

implicit none

    integer,parameter :: inside=0,left=1,right=2,lower=4,upper=8
    private
    public:: sp,stdout,cohensutherland,assert_isclose,loop_cohensutherland

contains

subroutine loop_cohensutherland(xmins,ymaxs,xmaxs,ymins,Np,x1,y1,x2,y2,length)
! for a single quad of points, loops over the boxes.
    
    integer(c_int), intent(in) :: Np
    real(sp),intent(in) :: xmins(Np),ymaxs(Np),xmaxs(Np),ymins(Np)
    
    real(sp),intent(inout):: x1,y1,x2,y2
    real(sp),intent(out) :: length(Np) !length of each intersection line segment
    
    integer i
    logical outside

    length = -1. !init

    do concurrent (i=1:Np)
        call cohensutherland(xmins(i), ymaxs(i),xmaxs(i),ymins(i),x1,y1,x2,y2,outside)
        if (.not.outside) length(i) = hypot((x2-x1),(y2-y1))
    end do


end subroutine loop_cohensutherland

pure subroutine cohensutherland(xmin,ymax,xmax,ymin, x1, y1, x2, y2,outside)
    
real(sp), intent(in) :: xmin,ymax,xmax,ymin
real(sp), intent(inout):: x1,y1,x2,y2
logical, intent(out) :: outside

integer k1,k2,opt ! just plain integers
real(sp) :: x,y

! check for trivially outside lines
k1 = getclip(x1,y1,xmin,xmax,ymin,ymax)
k2 = getclip(x2,y2,xmin,xmax,ymin,ymax)


do while (ior(k1,k2).ne.0)

    !trivially outside window, Reject
    if (iand(k1,k2).ne.0) then
        outside=.true.
        return
    endif

    opt = merge(k1,k2,k1.gt.0)
    if (iand(opt,UPPER).gt.0) then
        x = x1 + (x2 - x1) * (ymax - y1) / (y2 - y1)
        y = ymax
    else if (iand(opt,LOWER).gt.0) then
        x = x1 + (x2 - x1) * (ymin - y1) / (y2 - y1)
        y = ymin
    else if (iand(opt,RIGHT).gt.0) then
        y = y1 + (y2 - y1) * (xmax - x1) / (x2 - x1)
        x = xmax
    else if (iand(opt,LEFT).gt.0) then
        y = y1 + (y2 - y1) * (xmin - x1) / (x2 - x1)
        x = xmin
    endif
    
    if (opt.eq.k1) then
        x1 = x; y1 = y
        k1 = getclip(x1,y1,xmin,xmax,ymin,ymax)
    else if (opt.eq.k2) then
        x2 = x; y2 = y
        k2 = getclip(x2,y2,xmin,xmax,ymin,ymax)
    endif

end do


end subroutine cohensutherland


elemental function getclip(xa,ya,xmin,xmax,ymin,ymax) result(p) ! bit patterns
real(sp), intent(in) :: xa,ya,xmin,xmax,ymin,ymax


integer p
p = inside ! default

!consider x
if (xa.lt.xmin) then
    p = ior(p,left)
elseif (xa.gt.xmax) then
    p = ior(p,right)
endif

!consider y
if (ya.lt.ymin) then
    p = ior(p,lower)
elseif (ya.gt.ymax) then
    p = ior(p,upper)
endif

end function getclip

elemental logical function assert_isclose(x1,x2)
    real(sp),intent(in) :: x1,x2
    real(sp),parameter :: tol = 1e-3
    
    assert_isclose = abs(x1-x2).le.tol
end function assert_isclose

end module lineclip
